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
import Factory
import Foundation
import NanoViewControllerDIPrimitives
import UIKit
import XCTest

/// Test-bundle principal class — instantiated automatically by XCTest at bundle
/// load and re-applied before every individual test case.
///
/// **Why this exists:** real-world side effects like audio playback MUST be
/// modeled as injected dependencies and replaced with no-ops in tests so unit
/// tests never produce real audio (or other observable effects). Registering
/// here guarantees coverage even for tests that never call `setUp` themselves.
@objc(ZhipTestsBundle)
final class ZhipTestsBundle: NSObject, XCTestObservation {
    override init() {
        super.init()
        XCTestObservationCenter.shared.addTestObserver(self)
        // Disabling UIView animations makes `present(animated: true)` and
        // `dismiss(animated: true)` resolve on the next runloop tick instead
        // of spending ~0.35s per transition on the real animator. Coordinator
        // tests depend on this: without it, their 0.5s drains are effectively
        // mandatory, and the whole navigation suite costs seconds per test.
        UIView.setAnimationsEnabled(false)
        Self.registerSilentSideEffects()
    }

    func testCaseWillStart(_: XCTestCase) {
        // Container.shared.manager.reset() in test tearDown wipes registrations,
        // so we re-apply the silent defaults before each test starts.
        Self.registerSilentSideEffects()
    }

    private static func registerSilentSideEffects() {
        Container.shared.soundPlayer.register { MockSoundPlayer() }
        Container.shared.pasteboard.register { mainActorOnly { MockPasteboard() } }
        Container.shared.biometricsAuthenticator.register { MockBiometricsAuthenticator() }
        Container.shared.urlOpener.register { mainActorOnly { MockUrlOpener() } }
        Container.shared.clock.register { mainActorOnly { ImmediateClock() } }
        Container.shared.mainScheduler.register { mainActorOnly { ImmediateMainScheduler() } }
        Container.shared.htmlLoader.register { MockHtmlLoader() }
        Container.shared.hapticFeedback.register { mainActorOnly { MockHapticFeedback() } }
        Container.shared.dateProvider.register { FixedDateProvider() }
    }
}
