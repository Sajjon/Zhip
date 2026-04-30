import XCTest
@testable import AppFeature

final class PrivateKeyValidatorTests: XCTestCase {
    private let sut = PrivateKeyValidator()

    func test_validate_tooShort_returnsInvalidWithTooShort() {
        guard case let .invalid(.error(error)) = sut.validate(input: "deadbeef") else {
            return XCTFail("expected invalid")
        }
        if case .tooShort = error {} else { XCTFail("expected .tooShort, got \(error)") }
    }

    func test_validate_tooLong_returnsInvalidWithTooLong() {
        let input = String(repeating: "a", count: 65)
        guard case let .invalid(.error(error)) = sut.validate(input: input) else {
            return XCTFail("expected invalid")
        }
        if case .tooLong = error {} else { XCTFail("expected .tooLong, got \(error)") }
    }

    func test_validate_correctLengthButNotHex_returnsBadPrivateKey() {
        let input = String(repeating: "Z", count: 64)
        guard case let .invalid(.error(error)) = sut.validate(input: input) else {
            return XCTFail("expected invalid")
        }
        if case .badPrivateKey = error {} else { XCTFail("expected .badPrivateKey, got \(error)") }
    }

    func test_validate_validHex_returnsValid() {
        let input = String(repeating: "0", count: 63) + "1"
        if case .invalid = sut.validate(input: input) {
            XCTFail("expected valid")
        }
    }

    func test_errorMessage_tooShort_containsMissingCount() {
        let error = PrivateKeyValidator.Error.tooShort(lengthKeySubmitted: 60)
        XCTAssertFalse(error.errorMessage.isEmpty)
    }

    func test_errorMessage_tooLong_containsExcessCount() {
        let error = PrivateKeyValidator.Error.tooLong(lengthKeySubmitted: 70)
        XCTAssertFalse(error.errorMessage.isEmpty)
    }

    func test_errorMessage_badPrivateKey_hasBadMessage() {
        let error = PrivateKeyValidator.Error.badPrivateKey
        XCTAssertFalse(error.errorMessage.isEmpty)
    }
}
