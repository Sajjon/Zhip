import XCTest
import Validation
@testable import AppFeature

final class InputValidatorExtensionTests: XCTestCase {
    // MARK: - validate(input: nil) → .empty

    func test_validateNilInput_gasPrice_returnsEmpty() {
        let validator = GasPriceValidator()
        let result = validator.validate(input: nil)
        if case .invalid(.empty) = result { return }
        XCTFail("expected .invalid(.empty)")
    }

    func test_validateNilInput_gasLimit_returnsEmpty() {
        let validator = GasLimitValidator()
        let result = validator.validate(input: nil)
        if case .invalid(.empty) = result { return }
        XCTFail("expected .invalid(.empty)")
    }

    func test_validateNilInput_isNotValid() {
        let validator = GasLimitValidator()
        let result = validator.validate(input: nil)
        XCTAssertFalse(result.isValid)
    }

    func test_validateNilInput_keystore_returnsEmpty() {
        let validator = KeystoreValidator()
        let result = validator.validate(input: nil)
        if case .invalid(.empty) = result { return }
        XCTFail("expected .invalid(.empty)")
    }

    func test_validateNilInput_address_returnsEmpty() {
        let validator = AddressValidator()
        let result = validator.validate(input: nil)
        if case .invalid(.empty) = result { return }
        XCTFail("expected .invalid(.empty)")
    }

    // MARK: - error helper

    func test_errorHelper_returnsInvalidError() {
        let validator = GasLimitValidator()
        let result = validator.error(.nonNumericString)
        XCTAssertNotNil(result.error)
        XCTAssertTrue(result.isError)
    }
}
