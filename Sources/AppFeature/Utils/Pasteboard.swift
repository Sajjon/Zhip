// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation
import SingleLineControllerDIPrimitives

/// Project-wide constants for sensitive pasteboard writes.
/// Centralised so all sensitive copies share the same expiration window —
/// makes the policy easy to change in one place if (e.g.) UX research suggests
/// 30s or 90s is better.
///
/// The `Pasteboard` protocol + `DefaultPasteboard` implementation live in the
/// `SingleLineControllerDIPrimitives` package; this enum is Zhip-specific
/// policy that consumers reference when calling `pasteboard.copy(_:expiringAfter:)`.
public enum SensitivePasteboard {
    /// Expiration window applied to private-key, keystore, and similar
    /// security-sensitive copies. 60s gives the user time to paste into a
    /// password manager but limits the exposure window.
    static let expirationSeconds: TimeInterval = 60
}
