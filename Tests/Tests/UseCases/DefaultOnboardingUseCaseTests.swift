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
import XCTest

/// Unit tests for `DefaultOnboardingUseCase`.
///
/// The underlying `ZilliqaServiceReactive` is never exercised by the onboarding use
/// case (it only uses `Preferences` + `SecurePersistence`), so the test uses the
/// real `Container.shared.zilliqaService()` — which is fine because nothing in these
/// tests triggers network calls.
final class DefaultOnboardingUseCaseTests: XCTestCase {
    private var preferences: Preferences!
    private var secureStore: SecurePersistence!
    private var sut: DefaultOnboardingUseCase!

    override func setUp() {
        super.setUp()
        preferences = TestStoreFactory.makePreferences()
        secureStore = TestStoreFactory.makeSecurePersistence()
        sut = DefaultOnboardingUseCase(
            zilliqaService: Container.shared.zilliqaService(),
            preferences: preferences,
            securePersistence: secureStore
        )
    }

    override func tearDown() {
        sut = nil
        secureStore = nil
        preferences = nil
        Container.shared.manager.reset()
        super.tearDown()
    }

    // MARK: - Terms of Service

    func test_hasAcceptedTermsOfService_isFalse_initially() {
        XCTAssertFalse(sut.hasAcceptedTermsOfService)
    }

    func test_didAcceptTermsOfService_flipsFlagToTrue() {
        // Act
        sut.didAcceptTermsOfService()

        // Assert
        XCTAssertTrue(sut.hasAcceptedTermsOfService)
    }

    // MARK: - Pincode prompt

    func test_shouldPromptUserToChosePincode_isTrue_initially() {
        // Arrange: fresh store, no pincode configured, skipPincodeSetup not set

        // Act / Assert
        XCTAssertTrue(sut.shouldPromptUserToChosePincode)
    }

    func test_shouldPromptUserToChosePincode_isFalse_whenSkipPincodeSetupTrue() {
        preferences.save(value: true, for: .skipPincodeSetup)

        XCTAssertFalse(sut.shouldPromptUserToChosePincode)
    }

    func test_shouldPromptUserToChosePincode_isFalse_whenPincodeAlreadyConfigured() throws {
        let pincode = try Pincode(digits: [.one, .two, .three, .four])
        secureStore.save(pincode: pincode)

        XCTAssertFalse(sut.shouldPromptUserToChosePincode)
    }
}
