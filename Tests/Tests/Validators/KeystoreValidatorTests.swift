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
import XCTest
import Zesame

@MainActor
final class KeystoreValidatorTests: XCTestCase {
    private let sut = KeystoreValidator()

    func test_validate_validKeystoreJSON_returnsValid() {
        let json = TestWalletFactory.makeWallet().keystoreAsJSON

        if case .invalid = sut.validate(input: json) {
            XCTFail("expected valid")
        }
    }

    func test_validate_malformedJSON_returnsBadJSON() {
        guard case let .invalid(.error(error)) = sut.validate(input: "not json at all") else {
            return XCTFail("expected invalid")
        }
        if case .badJSON = error {} else { XCTFail("expected .badJSON, got \(error)") }
    }

    func test_validate_structurallyValidButWrongSchema_returnsBadJSON() {
        guard case let .invalid(.error(error)) = sut.validate(input: #"{"foo":"bar"}"#) else {
            return XCTFail("expected invalid")
        }
        if case .badJSON = error {} else { XCTFail("expected .badJSON, got \(error)") }
    }

    func test_errorMessage_badJSON_isNonEmpty() {
        let decodingError = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "x"))
        XCTAssertFalse(KeystoreValidator.Error.badJSON(decodingError).errorMessage.isEmpty)
    }

    func test_errorMessage_stringToDataConversionFailed_isNonEmpty() {
        XCTAssertFalse(KeystoreValidator.Error.stringToDataConversionFailed.errorMessage.isEmpty)
    }

    func test_errorMessage_incorrectPassword_isNonEmpty() {
        XCTAssertFalse(KeystoreValidator.Error.incorrectPassword.errorMessage.isEmpty)
    }

    func test_errorInit_fromIncorrectPasswordWalletImport_mapsToIncorrectPassword() {
        let error = KeystoreValidator.Error(walletImportError: .incorrectPassword)

        if case .incorrectPassword = error {} else {
            XCTFail("expected .incorrectPassword, got \(String(describing: error))")
        }
    }

    func test_errorInit_fromZesameWalletImportError_mapsToIncorrectPassword() {
        let zesameError = Zesame.Error.walletImport(.incorrectPassword)

        let error = KeystoreValidator.Error(error: zesameError)

        if case .incorrectPassword = error {} else {
            XCTFail("expected .incorrectPassword, got \(String(describing: error))")
        }
    }

    func test_errorInit_fromNonZesameError_returnsNil() {
        struct Other: Swift.Error {}

        let error = KeystoreValidator.Error(error: Other())

        XCTAssertNil(error)
    }

    func test_errorInit_fromWalletImportBadAddress_returnsNil() {
        let error = KeystoreValidator.Error(walletImportError: .badAddress)

        XCTAssertNil(error)
    }

    func test_errorInit_fromZesameErrorNotWalletImport_returnsNil() {
        let error = KeystoreValidator.Error(error: Zesame.Error.api(.timeout))

        XCTAssertNil(error)
    }
}
