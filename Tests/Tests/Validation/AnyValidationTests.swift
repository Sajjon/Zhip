import XCTest
import Validation
@testable import Zhip

final class AnyValidationTests: XCTestCase {
    // MARK: - isValid / isEmpty / isError

    func test_valid_isValidTrue_isEmptyFalse_isErrorFalse() {
        let sut = AnyValidation.valid(withRemark: nil)
        XCTAssertTrue(sut.isValid)
        XCTAssertFalse(sut.isEmpty)
        XCTAssertFalse(sut.isError)
    }

    func test_empty_isEmptyTrue_isValidFalse_isErrorFalse() {
        let sut = AnyValidation.empty
        XCTAssertTrue(sut.isEmpty)
        XCTAssertFalse(sut.isValid)
        XCTAssertFalse(sut.isError)
    }

    func test_errorMessage_isErrorTrue_isValidFalse_isEmptyFalse() {
        let sut = AnyValidation.errorMessage("boom")
        XCTAssertTrue(sut.isError)
        XCTAssertFalse(sut.isValid)
        XCTAssertFalse(sut.isEmpty)
    }

    // MARK: - Equatable

    func test_equatable_validMatchesOnRemark() {
        XCTAssertEqual(AnyValidation.valid(withRemark: nil), AnyValidation.valid(withRemark: nil))
        XCTAssertEqual(AnyValidation.valid(withRemark: "r"), AnyValidation.valid(withRemark: "r"))
        XCTAssertNotEqual(AnyValidation.valid(withRemark: "a"), AnyValidation.valid(withRemark: "b"))
    }

    func test_equatable_emptyMatchesEmpty() {
        XCTAssertEqual(AnyValidation.empty, AnyValidation.empty)
    }

    func test_equatable_errorMessageMatchesOnMessage() {
        XCTAssertEqual(AnyValidation.errorMessage("x"), AnyValidation.errorMessage("x"))
        XCTAssertNotEqual(AnyValidation.errorMessage("x"), AnyValidation.errorMessage("y"))
    }

    func test_equatable_differentCasesAreNotEqual() {
        XCTAssertNotEqual(AnyValidation.empty, AnyValidation.valid(withRemark: nil))
        XCTAssertNotEqual(AnyValidation.empty, AnyValidation.errorMessage("x"))
        XCTAssertNotEqual(AnyValidation.valid(withRemark: nil), AnyValidation.errorMessage("x"))
    }

    // MARK: - CustomStringConvertible

    func test_description_empty() {
        XCTAssertEqual(AnyValidation.empty.description, "empty")
    }

    func test_description_validNoRemark() {
        XCTAssertEqual(AnyValidation.valid(withRemark: nil).description, "valid")
    }

    func test_description_validWithRemark() {
        XCTAssertEqual(AnyValidation.valid(withRemark: "hint").description, "valid, with remark: hint")
    }

    func test_description_errorMessage() {
        XCTAssertEqual(AnyValidation.errorMessage("oops").description, "error: oops")
    }

    // MARK: - ValidationConvertible

    func test_validationConvertible_returnsSelf() {
        let sut = AnyValidation.empty
        XCTAssertEqual(sut.validation, sut)
    }

    // MARK: - Init from Validation

    func test_initFromValidation_validWithoutRemark() {
        let validation: Validation<Int, StubInputError> = .valid(1)
        XCTAssertEqual(AnyValidation(validation), .valid(withRemark: nil))
    }

    func test_initFromValidation_validWithRemark() {
        let validation: Validation<Int, StubInputError> = .valid(1, remark: StubInputError(message: "note"))
        XCTAssertEqual(AnyValidation(validation), .valid(withRemark: "note"))
    }

    func test_initFromValidation_invalidEmpty() {
        let validation: Validation<Int, StubInputError> = .invalid(.empty)
        XCTAssertEqual(AnyValidation(validation), .empty)
    }

    func test_initFromValidation_invalidError() {
        let validation: Validation<Int, StubInputError> = .invalid(.error(StubInputError(message: "bad")))
        XCTAssertEqual(AnyValidation(validation), .errorMessage("bad"))
    }
}

private struct StubInputError: InputError, Equatable {
    let message: String
    var errorMessage: String {
        message
    }
}
