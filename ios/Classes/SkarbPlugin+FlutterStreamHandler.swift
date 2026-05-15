//
//  SkarbPlugin+FlutterStreamHandler.swift
//  skarb_plugin
//
//  Bridges `SkarbPlugin`'s purchase-info notifications to the
//  `skarb_plugin/events` FlutterEventChannel. The channel is registered
//  in `SkarbPlugin.register(with:)`; this extension is the stream
//  handler that fills it.
//
//  All entry points run on the main thread:
//   * `onListen` / `onCancel` are dispatched by Flutter on the platform
//     (main) thread.
//   * Notification observers are registered with `queue: .main`.
//   * `dispatchPrecondition` asserts the contract.
//

import Flutter
import Foundation

extension SkarbPlugin: FlutterStreamHandler {
  // MARK: - Public (Interface) — FlutterStreamHandler
  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    dispatchPrecondition(condition: .onQueue(.main))
    eventSink = events
    installNotificationObservers()
    // Push the current cached snapshot right away so a fresh listener
    // doesn't have to wait for the next purchase to learn the state.
    if let info = manager?.userPurchasesInfo {
      events(info.toJson())
    }
    return nil
  }
  
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    dispatchPrecondition(condition: .onQueue(.main))
    observerBag.dispose()
    eventSink = nil
    return nil
  }
  
  // MARK: - Internal (Interface) — Observers
  func installNotificationObservers() {
    dispatchPrecondition(condition: .onQueue(.main))
    guard observerBag.isEmpty else { return }
    let center = NotificationCenter.default
    
    // Posted by `BitlicaSkarbManagerImplementation` after each
    // purchase/restore/validate succeeds.
    observerBag.add(center.addObserver(
      forName: BitlicaSkarbManagerImplementation
        .userPurchasesInfoDidUpdateNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.pushCachedInfo()
    })
    
    // Posted by SkarbSDK whenever its own cache refreshes (e.g. a
    // background receipt re-validation). Keeps Dart in sync with
    // SDK-driven updates we didn't initiate ourselves.
    observerBag.add(center.addObserver(
      forName: .skarbUserPurchaseInfoDidUpdate,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.pushCachedInfo()
    })
  }
  
  func pushCachedInfo() {
    dispatchPrecondition(condition: .onQueue(.main))
    guard let sink = eventSink else { return }
    sink(manager?.userPurchasesInfo?.toJson())
  }
}
