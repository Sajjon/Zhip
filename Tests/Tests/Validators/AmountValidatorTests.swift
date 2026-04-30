@testable import AppFeature
import XCTest
import Zesame

final class AmountValidatorTests: XCTestCase {
    func test_validate_validZilAmountString_returnsValid() {
        let sut = AmountValidator<Amount>()
        let result = sut.validate(input: (amountString: "5", unit: .zil))
        XCTAssertTrue(result.isValid)
    }

    func test_validate_nonNumericString_returnsInvalid() {
        let sut = AmountValidator<Amount>()
        let result = sut.validate(input: (amountString: "abc", unit: .zil))
        XCTAssertFalse(result.isValid)
    }

    func test_validate_emptyString_returnsInvalid() {
        let sut = AmountValidator<Amount>()
        let result = sut.validate(input: (amountString: "", unit: .zil))
        XCTAssertFalse(result.isValid)
    }

    func test_errorMessage_nonNumericString_hasMessage() {
        let error: AppFeature.AmountError<Amount> = .nonNumericString
        XCTAssertFalse(error.errorMessage.isEmpty)
    }

    func test_errorMessage_tooLarge_hasMessage() {
        let error: AppFeature.AmountError<Amount> = .tooLarge(max: "1000", unit: .zil)
        XCTAssertFalse(error.errorMessage.isEmpty)
    }

    func test_errorMessage_tooSmall_withUnit_hasMessage() {
        let error: AppFeature.AmountError<Amount> = .tooSmall(min: "1", unit: .zil, showUnit: true)
        XCTAssertFalse(error.errorMessage.isEmpty)
    }

    func test_errorMessage_tooSmall_withoutUnit_hasMessage() {
        let error: AppFeature.AmountError<Amount> = .tooSmall(min: "1", unit: .zil, showUnit: false)
        XCTAssertFalse(error.errorMessage.isEmpty)
    }

    func test_errorMessage_other_hasMessage() {
        struct DummyError: Swift.Error {}
        let error: AppFeature.AmountError<Amount> = .other(DummyError())
        XCTAssertFalse(error.errorMessage.isEmpty)
    }

    // MARK: - init(error:) dispatch

    func test_init_error_fromGasPriceError_tooLarge() throws {
        let maxGas = try GasPrice(qa: GasPrice.maxInQa)
        let zesameError = Zesame.AmountError<GasPrice>.tooLarge(max: maxGas)

        let error = AppFeature.AmountError<Amount>(error: zesameError)

        if case .tooLarge = error {} else { XCTFail("expected .tooLarge, got \(error)") }
    }

    func test_init_error_fromGasPriceError_tooSmall() throws {
        let minGas = try GasPrice(qa: GasPrice.minInQa)
        let zesameError = Zesame.AmountError<GasPrice>.tooSmall(min: minGas)

        let error = AppFeature.AmountError<Amount>(error: zesameError)

        if case .tooSmall = error {} else { XCTFail("expected .tooSmall, got \(error)") }
    }

    func test_init_error_fromZilError_nonNumericString() {
        let zesameError = Zesame.AmountError<Zil>.nonNumericString

        let error = AppFeature.AmountError<Amount>(error: zesameError)

        if case .nonNumericString = error {} else { XCTFail("expected .nonNumericString, got \(error)") }
    }

    func test_init_error_fromUnknownError_mapsToOther() {
        struct Custom: Swift.Error {}

        let error = AppFeature.AmountError<Amount>(error: Custom())

        if case .other = error {} else { XCTFail("expected .other, got \(error)") }
    }

    // MARK: - validate end-to-end

    func test_validate_largeZil_mapsToInvalid() {
        let sut = AmountValidator<Amount>()

        let result = sut.validate(input: (amountString: "10000000000000", unit: .zil))

        XCTAssertFalse(result.isValid)
    }

    func test_validate_stringEndingWithDecimal_returnsValidString() {
        let sut = AmountValidator<Amount>()
        let separator = Locale.current.decimalSeparatorForSure

        let result = sut.validate(input: (amountString: "5\(separator)", unit: .zil))

        if case let .valid(amountFromText, _) = result {
            XCTAssertNotNil(amountFromText.string)
        } else {
            XCTFail("expected valid-as-string, got \(result)")
        }
    }
}
