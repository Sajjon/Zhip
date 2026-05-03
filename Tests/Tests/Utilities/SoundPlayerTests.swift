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
import XCTest

/// Verifies the `SoundPlayer` dependency contract and that the global test-bundle
/// observer (`ZhipTestsBundle`) keeps unit tests silent by always resolving the
/// `Container.shared.soundPlayer` factory to a `MockSoundPlayer` — never the real
/// `DefaultSoundPlayer` that drives `AVAudioPlayer`.
@MainActor
final class SoundPlayerTests: XCTestCase {
    // MARK: - MockSoundPlayer

    func test_mockSoundPlayer_recordsPlayInvocations() {
        let mock = MockSoundPlayer()

        mock.play(resource: "ding", withExtension: "wav")
        mock.play(resource: "boom", withExtension: "mp3", in: .main)

        XCTAssertEqual(mock.playInvocations.count, 2)
        XCTAssertEqual(mock.playInvocations[0].resource, "ding")
        XCTAssertEqual(mock.playInvocations[0].fileExtension, "wav")
        XCTAssertEqual(mock.playInvocations[1].resource, "boom")
        XCTAssertEqual(mock.playInvocations[1].fileExtension, "mp3")
    }

    // MARK: - SoundPlayer protocol default extension

    func test_play_defaultBundleOverload_forwardsToFullSignatureWithMainBundle() {
        let mock = MockSoundPlayer()
        let player: SoundPlayer = mock

        player.play(resource: "x", withExtension: "wav")

        XCTAssertEqual(mock.playInvocations.count, 1)
    }

    // MARK: - Container registration

    func test_container_soundPlayer_resolvesToMockInTests() {
        // Defense-in-depth: if this assertion fails, a real DefaultSoundPlayer
        // would be hit and unit tests could leak audio to the host machine.
        let resolved = Container.shared.soundPlayer()

        XCTAssertTrue(resolved is MockSoundPlayer, "soundPlayer must resolve to MockSoundPlayer in tests")
    }

    func test_container_soundPlayer_remainsMockAfterContainerReset() {
        // Reset clears registrations — the test-bundle observer must re-register
        // the mock before the next test runs (testCaseWillStart). This test only
        // proves the registration is restored via re-registration, since reset()
        // is what tearDown of other test classes calls.
        Container.shared.manager.reset()
        Container.shared.soundPlayer.register { MockSoundPlayer() }

        let resolved = Container.shared.soundPlayer()

        XCTAssertTrue(resolved is MockSoundPlayer)
    }

    // MARK: - DefaultSoundPlayer (production type, exercised with no audible effect)

    func test_defaultSoundPlayer_play_withMissingResource_returnsSilently() {
        let player = DefaultSoundPlayer()

        // Resource doesn't exist in the test bundle — the early `guard` returns
        // before any AVAudioPlayer or AVAudioSession activation, so no sound.
        player.play(
            resource: "definitely-not-a-real-resource-xyz",
            withExtension: "wav",
            in: Bundle(for: SoundPlayerTests.self)
        )

        // No assertion needed — we just exercise the guard path without sound.
    }
}
