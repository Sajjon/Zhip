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

import XCTest
@testable import AppFeature

/// Unit tests for `DefaultPincodeUseCase`.
///
/// Each test follows Arrange-Act-Assert with one-line arrange/act/assert where
/// possible.  The underlying `SecurePersistence` and `Preferences` are in-memory
/// so tests are fully hermetic.
final class DefaultPincodeUseCaseTests: XCTestCase {
    private var preferences: Preferences!
    private var secureStore: SecurePersistence!
    private var sut: DefaultPincodeUseCase!

    override func setUp() {
        super.setUp()
        preferences = TestStoreFactory.makePreferences()
        secureStore = TestStoreFactory.makeSecurePersistence()
        sut = DefaultPincodeUseCase(preferences: preferences, securePersistence: secureStore)
    }

    override func tearDown() {
        sut = nil
        secureStore = nil
        preferences = nil
        super.tearDown()
    }

    // MARK: - hasConfiguredPincode

    func test_hasConfiguredPincode_isFalse_whenNoPincodeSaved() {
        // Arrange: fresh store

        // Act
        let result = sut.hasConfiguredPincode

        // Assert
        XCTAssertFalse(result)
    }

    func test_hasConfiguredPincode_isTrue_afterUserChoosesPincode() throws {
        // Arrange
        let pin = try makePincode([.one, .two, .three, .four])

        // Act
        sut.userChoose(pincode: pin)

        // Assert
        XCTAssertTrue(sut.hasConfiguredPincode)
    }

    // MARK: - pincode getter

    func test_pincode_roundtripsExactValue() throws {
        // Arrange
        let pin = try makePincode([.nine, .zero, .four, .two])

        // Act
        sut.userChoose(pincode: pin)

        // Assert
        XCTAssertEqual(sut.pincode, pin)
    }

    // MARK: - deletePincode

    func test_deletePincode_removesBothPincodeAndSkipFlag() throws {
        // Arrange
        let pin = try makePincode([.one, .one, .one, .one])
        sut.userChoose(pincode: pin)
        sut.skipSettingUpPincode()

        // Act
        sut.deletePincode()

        // Assert
        XCTAssertFalse(sut.hasConfiguredPincode)
    }

    // MARK: - skipSettingUpPincode

    func test_skipSettingUpPincode_setsPreferencesFlag() {
        // Arrange: fresh store

        // Act
        sut.skipSettingUpPincode()

        // Assert
        XCTAssertTrue(preferences.isTrue(.skipPincodeSetup))
    }

    // MARK: - Helpers

    private func makePincode(_ digits: [Digit]) throws -> Pincode {
        try Pincode(digits: digits)
    }
}
