@testable import AppFeature
import XCTest

@MainActor
final class EncryptionPasswordValidatorTests: XCTestCase {
    func test_newWallet_mismatch_returnsPasswordsDoesNotMatch() {
        let sut = EncryptionPasswordValidator(mode: .newOrRestorePrivateKey)
        guard case let .invalid(.error(error)) = sut
            .validate(input: (password: "abcdefgh", confirmingPassword: "xxxx"))
        else {
            return XCTFail("expected invalid")
        }
        XCTAssertEqual(error, .passwordsDoesNotMatch)
    }

    func test_newWallet_tooShort_returnsPasswordIsTooShort() {
        let sut = EncryptionPasswordValidator(mode: .newOrRestorePrivateKey)
        guard case let .invalid(.error(error)) = sut.validate(input: (password: "abc", confirmingPassword: "abc"))
        else {
            return XCTFail("expected invalid")
        }
        // Equatable treats all .passwordIsTooShort equal via the project's ==.
        XCTAssertEqual(error, .passwordIsTooShort(mustAtLeastHaveLength: 8))
    }

    func test_newWallet_matchingAndLongEnough_returnsValid() {
        let sut = EncryptionPasswordValidator(mode: .newOrRestorePrivateKey)
        guard case .valid = sut.validate(input: (password: "12345678", confirmingPassword: "12345678")) else {
            return XCTFail("expected valid")
        }
    }

    func test_errorMessage_passwordsDoesNotMatch_hasMessage() {
        XCTAssertFalse(WalletEncryptionPassword.Error.passwordsDoesNotMatch.errorMessage.isEmpty)
    }

    func test_errorMessage_passwordIsTooShort_hasMessage() {
        XCTAssertFalse(WalletEncryptionPassword.Error.passwordIsTooShort(mustAtLeastHaveLength: 8).errorMessage.isEmpty)
    }

    func test_errorMessage_incorrectPassword_duringBackup_hasMessage() {
        XCTAssertFalse(WalletEncryptionPassword.Error.incorrectPassword(backingUpWalletJustCreated: true).errorMessage
            .isEmpty)
    }

    func test_errorMessage_incorrectPassword_regular_hasMessage() {
        XCTAssertFalse(WalletEncryptionPassword.Error.incorrectPassword(backingUpWalletJustCreated: false).errorMessage
            .isEmpty)
    }

    func test_mode_minimumPasswordLength_newOrRestorePrivateKey_is8() {
        XCTAssertEqual(WalletEncryptionPassword.Mode.newOrRestorePrivateKey.minimumPasswordLength, 8)
    }
}
