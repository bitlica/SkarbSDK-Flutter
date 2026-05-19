//
//  PurchaseInfoEventBridge.swift
//  skarb_plugin
//
//  Bridges iOS NotificationCenter signals about purchase-info cache
//  refreshes to a Flutter EventChannel. Listens only to the manager's
//  own `userPurchasesInfoDidUpdateNotification`, which the manager
//  fans out for both directly-initiated flows (purchase / restore /
//  validate) and SDK-driven cache refreshes (it observes
//  `.skarbUserPurchaseInfoDidUpdate` and re-broadcasts). This keeps the
//  data flow one-directional: SDK → manager → bridge → Dart, with no
//  parallel listeners on the SDK-level notification.
//
//  All entry points run on the main thread:
//   * `onListen` / `onCancel` are dispatched by Flutter on the platform
//     (main) thread.
//   * Notification observers are registered with `queue: .main`.
//   * `dispatchPrecondition` asserts the contract.
//

import Flutter
import Foundation

final class PurchaseInfoEventBridge: NSObject, FlutterStreamHandler {

    // MARK: - Private (Properties)

    private weak var manager: BitlicaSkarbManager?
    private var eventSink: FlutterEventSink?
    private let observerBag = NotificationObserverBag()

    // MARK: - Public (Interface)

    /// Wires up the manager whose cached `userPurchasesInfo` is forwarded
    /// to Dart. Called by `SkarbPlugin` after `initialize` lands.
    func attach(manager: BitlicaSkarbManager) {
        dispatchPrecondition(condition: .onQueue(.main))
        self.manager = manager
        // If a Dart listener already attached before `initialize`, replay
        // the now-available snapshot.
        pushCachedInfo()
    }

    // MARK: - Public (Interface) — FlutterStreamHandler

    func onListen(
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

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        dispatchPrecondition(condition: .onQueue(.main))
        observerBag.dispose()
        eventSink = nil
        return nil
    }

    // MARK: - Private (Interface) — Observers

    private func installNotificationObservers() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard observerBag.isEmpty else { return }
        let center = NotificationCenter.default

        // Single source: the manager fans out both directly-initiated
        // updates (purchase / restore / validate callbacks) and
        // SDK-driven cache refreshes (it observes
        // `.skarbUserPurchaseInfoDidUpdate` and re-posts). Subscribing
        // only here keeps the flow one-directional and avoids duplicate
        // events.
        observerBag.add(center.addObserver(
            forName: BitlicaSkarbManagerImplementation
                .userPurchasesInfoDidUpdateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pushCachedInfo()
        })
    }

    private func pushCachedInfo() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard let sink = eventSink else { return }
        sink(manager?.userPurchasesInfo?.toJson())
    }
}
