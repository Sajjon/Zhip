import XCTest
import Validation
@testable import Zhip

final class ValidationTests: XCTestCase {
    // MARK: - .valid(value)

    func test_validConvenience_wrapsValueWithNilRemark() {
        let sut: Validation<Int, StubError> = .valid(42)
        XCTAssertEqual(sut.value, 42)
        XCTAssertTrue(sut.isValid)
        XCTAssertFalse(sut.isError)
        XCTAssertNil(sut.error)
    }

    // MARK: - value / isValid

    func test_value_returnsNilForInvalidEmpty() {
        let sut: Validation<Int, StubError> = .invalid(.empty)
        XCTAssertNil(sut.value)
        XCTAssertFalse(sut.isValid)
    }

    func test_value_returnsNilForInvalidError() {
        let sut: Validation<Int, StubError> = .invalid(.error(StubError(message: "nope")))
        XCTAssertNil(sut.value)
        XCTAssertFalse(sut.isValid)
    }

    // MARK: - error / isError

    func test_error_returnsErrorInstance_forInvalidError() {
        let original = StubError(message: "boom")
        let sut: Validation<Int, StubError> = .invalid(.error(original))
        XCTAssertNotNil(sut.error)
        XCTAssertTrue(sut.isError)
    }

    func test_error_returnsNilForValid() {
        let sut: Validation<Int, StubError> = .valid(1)
        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.isError)
    }

    func test_error_returnsNilForInvalidEmpty() {
        let sut: Validation<Int, StubError> = .invalid(.empty)
        XCTAssertNil(sut.error)
        XCTAssertFalse(sut.isError)
    }

    // MARK: - remark preserved

    func test_valid_withRemarkRetainsRemark() {
        let sut: Validation<Int, StubError> = .valid(5, remark: StubError(message: "note"))
        XCTAssertEqual(sut.value, 5)
    }

    // MARK: - Equatable

    func test_equatable_validCasesAreEqual() {
        let a: Validation<Int, StubError> = .valid(1)
        let b: Validation<Int, StubError> = .valid(2)
        XCTAssertEqual(a, b)
    }

    func test_equatable_invalidEmptyCasesAreEqual() {
        let a: Validation<Int, StubError> = .invalid(.empty)
        let b: Validation<Int, StubError> = .invalid(.empty)
        XCTAssertEqual(a, b)
    }

    func test_equatable_invalidErrorCompareViaIsEqual() {
        let a: Validation<Int, StubError> = .invalid(.error(StubError(message: "a")))
        let b: Validation<Int, StubError> = .invalid(.error(StubError(message: "a")))
        XCTAssertEqual(a, b)
    }

    func test_equatable_differentCasesAreNotEqual() {
        let valid: Validation<Int, StubError> = .valid(1)
        let empty: Validation<Int, StubError> = .invalid(.empty)
        let error: Validation<Int, StubError> = .invalid(.error(StubError(message: "x")))
        XCTAssertNotEqual(valid, empty)
        XCTAssertNotEqual(valid, error)
        XCTAssertNotEqual(empty, error)
    }

    // MARK: - CustomStringConvertible

    func test_description_valid_noRemark() {
        let sut: Validation<Int, StubError> = .valid(1)
        XCTAssertEqual(sut.description, "Valid")
    }

    func test_description_valid_withRemark() {
        let sut: Validation<Int, StubError> = .valid(1, remark: StubError(message: "hint"))
        XCTAssertEqual(sut.description, "Valid with remark: hint")
    }

    func test_description_invalidEmpty() {
        let sut: Validation<Int, StubError> = .invalid(.empty)
        XCTAssertEqual(sut.description, "empty")
    }

    func test_description_invalidError() {
        let sut: Validation<Int, StubError> = .invalid(.error(StubError(message: "oops")))
        XCTAssertEqual(sut.description, "error: oops")
    }

    // MARK: - ValidationConvertible

    func test_validationConvertible_validWithoutRemark_mapsToAnyValidationValid() {
        let sut: Validation<Int, StubError> = .valid(1)
        XCTAssertEqual(sut.validation, .valid(withRemark: nil))
    }

    func test_validationConvertible_validWithRemark_mapsToAnyValidationWithRemark() {
        let sut: Validation<Int, StubError> = .valid(1, remark: StubError(message: "note"))
        XCTAssertEqual(sut.validation, .valid(withRemark: "note"))
    }

    func test_validationConvertible_invalidEmpty_mapsToEmpty() {
        let sut: Validation<Int, StubError> = .invalid(.empty)
        XCTAssertEqual(sut.validation, .empty)
    }

    func test_validationConvertible_invalidError_mapsToErrorMessage() {
        let sut: Validation<Int, StubError> = .invalid(.error(StubError(message: "bad")))
        XCTAssertEqual(sut.validation, .errorMessage("bad"))
    }
}

private struct StubError: InputError, Equatable {
    let message: String
    var errorMessage: String {
        message
    }
}
