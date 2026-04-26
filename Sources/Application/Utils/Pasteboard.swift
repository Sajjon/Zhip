//
// MIT License
//
// Copyright (c) 2018-2026 Open Zesame (https://github.com/OpenZesame)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import UIKit

/// Abstracts the system pasteboard so view-models can copy user-visible text
/// without touching `UIPasteboard.general` directly. Unit tests register a
/// `MockPasteboard` that records values instead of mutating the real pasteboard.
protocol Pasteboard: AnyObject {
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

extension Pasteboard {
    /// Convenience for non-sensitive copies — no expiration.
    func copy(_ string: String) {
        copy(string, expiringAfter: nil)
    }
}

/// Project-wide constants for sensitive pasteboard writes.
/// Centralised so all sensitive copies share the same expiration window —
/// makes the policy easy to change in one place if (e.g.) UX research suggests
/// 30s or 90s is better.
enum SensitivePasteboard {
    /// Expiration window applied to private-key, keystore, and similar
    /// security-sensitive copies. 60s gives the user time to paste into a
    /// password manager but limits the exposure window.
    static let expirationSeconds: TimeInterval = 60
}

/// Production implementation that writes through to `UIPasteboard.general`.
final class DefaultPasteboard: Pasteboard {
    init() {}

    /// Writes `string` to `UIPasteboard.general`. With `expiringAfter` set,
    /// uses `setItems(_:options:)` with `.expirationDate` so the system
    /// auto-clears the entry — the pasteboard doesn't auto-sync to Universal
    /// Clipboard once expired.
    func copy(_ string: String, expiringAfter: TimeInterval?) {
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
