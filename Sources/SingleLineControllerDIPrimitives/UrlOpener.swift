// MIT License — Copyright (c) 2018-2026 Open Zesame

import UIKit

/// Abstracts `UIApplication.shared.open(_:)` so tests can register a no-op
/// implementation. In the iOS simulator the real call can dispatch a
/// workspace round-trip that never completes within a unit-test timeout.
public protocol UrlOpener: AnyObject {
    /// Hands `url` off to the system to open in the registered handler app.
    func open(_ url: URL)
}

/// Production implementation that forwards to `UIApplication.shared.open`.
public final class DefaultUrlOpener: UrlOpener {
    /// Trivial init — no dependencies.
    public init() {}

    /// Opens `url` via the system app-launch flow. No options, no callback.
    public func open(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
