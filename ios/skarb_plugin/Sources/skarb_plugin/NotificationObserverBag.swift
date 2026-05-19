//
//  NotificationObserverBag.swift
//  skarb_plugin
//
//  RAII-style holder for `NotificationCenter` observer tokens. Removes
//  all retained observers automatically on `dispose()` (re-subscribe
//  path) and on `deinit` (plugin teardown / process exit safety net).
//

import Foundation

final class NotificationObserverBag {
  // MARK: - Private (Properties)
  private var tokens: [NSObjectProtocol] = []
  
  // MARK: - Public (Interface)
  var isEmpty: Bool { tokens.isEmpty }
  
  func add(_ token: NSObjectProtocol) {
    tokens.append(token)
  }
  
  func dispose() {
    let center = NotificationCenter.default
    for token in tokens {
      center.removeObserver(token)
    }
    tokens.removeAll()
  }
  
  // MARK: - Lifecycle
  deinit {
    dispose()
  }
}
