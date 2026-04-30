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

@testable import AppFeature
import Foundation
import SingleLineControllerDIPrimitives

/// In-test `UrlOpener` that NEVER forwards to `UIApplication.shared.open(_:)`.
/// Records every dispatched URL so tests can assert which external navigation
/// target was requested without triggering a real OS-level open (which hangs
/// the runloop in the iOS simulator).
final class MockUrlOpener: UrlOpener {
    /// The most recent URL passed to `open(_:)`, or `nil` if none yet.
    private(set) var lastOpenedUrl: URL?

    /// Every URL passed to `open(_:)`, in call order.
    private(set) var openInvocations: [URL] = []

    init() {}

    func open(_ url: URL) {
        lastOpenedUrl = url
        openInvocations.append(url)
    }
}
