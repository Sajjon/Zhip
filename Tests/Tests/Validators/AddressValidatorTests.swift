@testable import AppFeature
import XCTest
import Zesame

final class AddressValidatorTests: XCTestCase {
    private let sut = AddressValidator()

    func test_validate_validChecksummedAddress_returnsValid() {
        let valid = "e3090a1309DfAC40352d03dEc6cCD9cAd213e76B"

        if case .invalid = sut.validate(input: valid) {
            XCTFail("expected valid")
        }
    }

    func test_validate_emptyString_returnsInvalid() {
        guard case .invalid = sut.validate(input: "") else {
            return XCTFail("expected invalid")
        }
    }

    func test_validate_garbageString_returnsInvalid() {
        guard case .invalid = sut.validate(input: "this is not an address") else {
            return XCTFail("expected invalid")
        }
    }

    func test_validate_tooShortHex_returnsInvalid() {
        guard case .invalid = sut.validate(input: "0x123") else {
            return XCTFail("expected invalid")
        }
    }

    func test_errorMessage_incorrectLength_tooLong_hasMessage() {
        let error = AddressValidator.Error.incorrectLength(expectedLength: 20, butGot: 30)
        XCTAssertFalse(error.errorMessage.isEmpty)
    }

    func test_errorMessage_incorrectLength_tooShort_hasMessage() {
        let error = AddressValidator.Error.incorrectLength(expectedLength: 20, butGot: 10)
        XCTAssertFalse(error.errorMessage.isEmpty)
    }

    func test_errorMessage_notChecksummed_hasMessage() {
        let error = AddressValidator.Error.notChecksummed
        XCTAssertFalse(error.errorMessage.isEmpty)
    }

    func test_errorMessage_noBech32NorHexstring_hasMessage() {
        let error = AddressValidator.Error.noBech32NorHexstring
        XCTAssertFalse(error.errorMessage.isEmpty)
    }

    // MARK: - fromAddressError init

    func test_errorInit_incorrectLength_mapsToIncorrectLength() {
        let zesame = Zesame.Address.Error.incorrectLength(expectedLength: 40, forStyle: .ethereum, butGot: 42)

        let mapped = AddressValidator.Error(fromAddressError: zesame)

        guard case let .incorrectLength(expectedLength, butGot) = mapped else {
            return XCTFail("expected .incorrectLength, got \(mapped)")
        }
        XCTAssertEqual(expectedLength, 40)
        XCTAssertEqual(butGot, 42)
    }

    func test_errorInit_notChecksummed_mapsToNotChecksummed() {
        let mapped = AddressValidator.Error(fromAddressError: .notChecksummed)

        if case .notChecksummed = mapped {} else { XCTFail("expected .notChecksummed") }
    }

    func test_errorInit_bech32DataEmpty_mapsToNoBech32NorHexstring() {
        let mapped = AddressValidator.Error(fromAddressError: .bech32DataEmpty)

        if case .noBech32NorHexstring = mapped {} else { XCTFail("expected .noBech32NorHexstring") }
    }

    func test_errorInit_notHexadecimal_mapsToNoBech32NorHexstring() {
        let mapped = AddressValidator.Error(fromAddressError: .notHexadecimal)

        if case .noBech32NorHexstring = mapped {} else { XCTFail("expected .noBech32NorHexstring") }
    }

    func test_errorInit_invalidBech32_checksumMismatch_mapsToNotChecksummed() {
        let mapped = AddressValidator.Error(fromAddressError: .invalidBech32Address(bechError: .checksumMismatch))

        if case .notChecksummed = mapped {} else { XCTFail("expected .notChecksummed") }
    }
}
