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
import XCTest
import Zesame

final class WalletEncryptionPasswordTests: XCTestCase {
    // MARK: - init

    func test_init_mismatchedConfirm_throwsPasswordsDoesNotMatch() {
        XCTAssertThrowsError(
            try WalletEncryptionPassword(password: "abcdefgh", confirm: "ABCDEFGH", mode: .newOrRestorePrivateKey)
        ) { error in
            if case WalletEncryptionPassword.Error.passwordsDoesNotMatch = error {} else {
                XCTFail("expected .passwordsDoesNotMatch, got \(error)")
            }
        }
    }

    func test_init_tooShort_throwsPasswordIsTooShort() {
        XCTAssertThrowsError(
            try WalletEncryptionPassword(password: "abc", confirm: "abc", mode: .newOrRestorePrivateKey)
        ) { error in
            if case let WalletEncryptionPassword.Error.passwordIsTooShort(minimum) = error {
                XCTAssertEqual(minimum, 8)
            } else {
                XCTFail("expected .passwordIsTooShort, got \(error)")
            }
        }
    }

    func test_init_validNewOrRestore_succeeds() throws {
        let sut = try WalletEncryptionPassword(password: "abcdefgh", confirm: "abcdefgh", mode: .newOrRestorePrivateKey)

        XCTAssertEqual(sut.validPassword, "abcdefgh")
    }

    func test_init_restoreKeystoreRespectsZesameMinimum() {
        let mode = WalletEncryptionPassword.Mode.restoreKeystore

        XCTAssertEqual(mode.minimumPasswordLength, Zesame.Keystore.minimumPasswordLength)
    }

    // MARK: - minimumLength / modeFrom / minimumLengthForWallet

    func test_minimumLength_newOrRestorePrivateKey_returnsEight() {
        XCTAssertEqual(WalletEncryptionPassword.minimumLength(mode: .newOrRestorePrivateKey), 8)
    }

    func test_minimumLength_restoreKeystore_returnsZesameMinimum() {
        XCTAssertEqual(
            WalletEncryptionPassword.minimumLength(mode: .restoreKeystore),
            Zesame.Keystore.minimumPasswordLength
        )
    }

    func test_modeFrom_generatedByThisApp_isNewOrRestorePrivateKey() {
        let wallet = TestWalletFactory.makeWallet(origin: .generatedByThisApp)

        XCTAssertEqual(WalletEncryptionPassword.modeFrom(wallet: wallet), .newOrRestorePrivateKey)
    }

    func test_modeFrom_importedPrivateKey_isNewOrRestorePrivateKey() {
        let wallet = TestWalletFactory.makeWallet(origin: .importedPrivateKey)

        XCTAssertEqual(WalletEncryptionPassword.modeFrom(wallet: wallet), .newOrRestorePrivateKey)
    }

    func test_modeFrom_importedKeystore_isRestoreKeystore() {
        let wallet = TestWalletFactory.makeWallet(origin: .importedKeystore)

        XCTAssertEqual(WalletEncryptionPassword.modeFrom(wallet: wallet), .restoreKeystore)
    }

    func test_minimumLengthForWallet_forwardsToMode() {
        let wallet = TestWalletFactory.makeWallet(origin: .importedKeystore)

        XCTAssertEqual(
            WalletEncryptionPassword.minimumLengthForWallet(wallet),
            Zesame.Keystore.minimumPasswordLength
        )
    }

    // MARK: - Error mapping

    func test_incorrectPasswordErrorFromWalletImport_matchesIncorrectPassword() {
        let result = WalletEncryptionPassword.Error.incorrectPasswordErrorFrom(
            walletImportError: .incorrectPassword,
            backingUpWalletJustCreated: true
        )

        if case let .incorrectPassword(backingUp) = result {
            XCTAssertTrue(backingUp)
        } else {
            XCTFail("expected .incorrectPassword, got \(String(describing: result))")
        }
    }

    func test_incorrectPasswordErrorFromWalletImport_nonMatching_returnsNil() {
        let result = WalletEncryptionPassword.Error.incorrectPasswordErrorFrom(
            walletImportError: .jsonStringDecoding
        )

        XCTAssertNil(result)
    }

    func test_incorrectPasswordErrorFromError_fromZesameIncorrectPassword_matches() {
        let zesameError = Zesame.Error.walletImport(.incorrectPassword)

        let result = WalletEncryptionPassword.Error.incorrectPasswordErrorFrom(error: zesameError)

        if case .incorrectPassword = result {} else {
            XCTFail("expected .incorrectPassword, got \(String(describing: result))")
        }
    }

    func test_incorrectPasswordErrorFromError_fromOtherError_returnsNil() {
        struct Other: Swift.Error {}

        let result = WalletEncryptionPassword.Error.incorrectPasswordErrorFrom(error: Other())

        XCTAssertNil(result)
    }
}
