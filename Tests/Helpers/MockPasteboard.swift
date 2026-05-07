//
// MIT License
//
// Copyright (c) 2018-2026 Alexander Cyon (https://github.com/sajjon)
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

@testable import AppFeature
import Foundation
import NanoViewControllerDIPrimitives

/// In-test `Pasteboard` that NEVER mutates the real `UIPasteboard.general`.
/// Records each `copy(...)` invocation so tests can assert on intent without
/// leaking clipboard data across test runs or onto the host device.
final class MockPasteboard: Pasteboard {
    /// The most recent string passed to `copy(_:expiringAfter:)`, or `nil` if
    /// no copy has occurred since this mock was created or reset.
    private(set) var copiedString: String?

    /// The most recent expiration interval passed to `copy(_:expiringAfter:)`,
    /// or `nil` if the last copy did not specify one. Tests assert on this to
    /// confirm sensitive copies (private key, keystore) get the expected
    /// auto-clear policy.
    private(set) var copiedExpiringAfter: TimeInterval?

    /// Every (string, expiringAfter) pair passed to `copy(_:expiringAfter:)`,
    /// in call order.
    private(set) var copyInvocations: [(string: String, expiringAfter: TimeInterval?)] = []

    init() {}

    func copy(_ string: String, expiringAfter: TimeInterval?) {
        copiedString = string
        copiedExpiringAfter = expiringAfter
        copyInvocations.append((string: string, expiringAfter: expiringAfter))
    }
}
