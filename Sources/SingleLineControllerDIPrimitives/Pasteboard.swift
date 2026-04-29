// MIT License — Copyright (c) 2018-2026 Open Zesame

import UIKit

/// Abstracts the system pasteboard so view-models can copy user-visible text
/// without touching `UIPasteboard.general` directly. Unit tests register a
/// `MockPasteboard` that records values instead of mutating the real pasteboard.
public protocol Pasteboard: AnyObject {
    /// Copy `string` to the system pasteboard.
    ///
    /// - Parameters:
    ///   - string: The value to write.
    ///   - expiringAfter: Optional auto-clear interval (seconds). Use this for
    ///     anything sensitive (keystore JSON, private keys, mnemonics) so the
    ///     value doesn't sit on the system pasteboard indefinitely — it would
    ///     otherwise sync to Universal Clipboard, get picked up by clipboard
    ///     managers, etc. `nil` (default) keeps the legacy "no expiration"
    ///     behaviour for non-sensitive copies (receive address, transaction id).
    func copy(_ string: String, expiringAfter: TimeInterval?)
}

public extension Pasteboard {
    /// Convenience for non-sensitive copies — no expiration.
    func copy(_ string: String) {
        copy(string, expiringAfter: nil)
    }
}

/// Production implementation that writes through to `UIPasteboard.general`.
public final class DefaultPasteboard: Pasteboard {
    public init() {}

    /// Writes `string` to `UIPasteboard.general`. With `expiringAfter` set,
    /// uses `setItems(_:options:)` with `.expirationDate` so the system
    /// auto-clears the entry — the pasteboard doesn't auto-sync to Universal
    /// Clipboard once expired.
    public func copy(_ string: String, expiringAfter: TimeInterval?) {
        guard let expiringAfter else {
            UIPasteboard.general.string = string
            return
        }
        let expirationDate = Date().addingTimeInterval(expiringAfter)
        UIPasteboard.general.setItems(
            [[UIPasteboard.typeAutomatic: string]],
            options: [.expirationDate: expirationDate]
        )
    }
}
