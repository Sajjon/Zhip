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

/// Test-bundle factory for `UIWindow` instances used by coordinator /
/// snapshot tests.
///
/// Prefers `UIWindow(windowScene:)` (the iOS 26-blessed initialiser) when a
/// foreground `UIWindowScene` is available — the XCTest harness on the
/// simulator typically supplies one. Falls back to the deprecated
/// `init(frame:)` *only* when no scene is present (e.g. headless macOS test
/// runs of the package), in which case the fallback is silenced via a
/// dedicated availability shim so consumers don't see the warning at every
/// `setUp` site.
@MainActor
enum TestWindowFactory {
    /// Default test-window dimensions — 320x480 mirrors the size most
    /// existing coordinator tests opted into for layout determinism.
    /// `nonisolated` so it's usable as a default-argument value (default
    /// arguments evaluate in the caller's isolation, which may not be
    /// `@MainActor`).
    nonisolated static let defaultFrame = CGRect(x: 0, y: 0, width: 320, height: 480)

    /// Creates a window suitable for hosting a navigation controller / view
    /// in tests, using the iOS 26-blessed `UIWindow(windowScene:)`
    /// initialiser. The XCTest harness always supplies a
    /// `UIWindowScene` on the simulator, so this is unconditionally safe
    /// for every test runner Zhip uses.
    ///
    /// Traps with a clear message if no `UIWindowScene` is available —
    /// previously the fallback was a deprecated `UIWindow(frame:)` call,
    /// but that produced a deprecation warning at every test setUp; the
    /// trap-on-missing-scene path is cleaner and equally correct because
    /// the failure mode is "the test harness is misconfigured", not "we
    /// need to support headless macOS test runs".
    static func make(frame: CGRect = defaultFrame) -> UIWindow {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first
        else {
            fatalError("TestWindowFactory.make() requires a UIWindowScene; none found in UIApplication.shared.connectedScenes. Run tests on the iOS simulator.")
        }
        let window = UIWindow(windowScene: windowScene)
        window.frame = frame
        return window
    }
}
