import XCTest
import Zesame
@testable import Zhip

final class SufficientFundsValidatorTests: XCTestCase {
    func test_validate_missingAmount_returnsEmpty() {
        let sut = SufficientFundsValidator()
        let result = sut.validate(input: (amount: nil, gasLimit: nil, gasPrice: nil, balance: nil))
        XCTAssertFalse(result.isValid)
        XCTAssertFalse(result.isError)
    }

    func test_errorMessage_insufficientFunds_hasMessage() {
        let error = SufficientFundsValidator.Error.insufficientFunds
        XCTAssertFalse(error.errorMessage.isEmpty)
    }

    func test_errorMessage_amountError_delegatesToInner() {
        let inner: Zhip.AmountError<Amount> = .nonNumericString
        let error = SufficientFundsValidator.Error.amountError(inner)
        XCTAssertEqual(error.errorMessage, inner.errorMessage)
    }

    func test_validate_sufficientFunds_returnsValid() throws {
        let sut = SufficientFundsValidator()
        let amount = try Amount(zil: 1)
        let gasPrice = try GasPrice(li: 1_000_000)
        let gasLimit = GasLimit.minimum
        let balance = try Amount(zil: 100)

        let result = sut.validate(input: (amount: amount, gasLimit: gasLimit, gasPrice: gasPrice, balance: balance))

        XCTAssertTrue(result.isValid)
    }

    func test_validate_totalCostExceedsBalance_returnsInsufficientFunds() throws {
        let sut = SufficientFundsValidator()
        let amount = try Amount(zil: 100)
        let gasPrice = try GasPrice(li: 1_000_000)
        let gasLimit = GasLimit.minimum
        let balance = try Amount(qa: "1")

        let result = sut.validate(input: (amount: amount, gasLimit: gasLimit, gasPrice: gasPrice, balance: balance))

        guard case let .invalid(.error(error)) = result else {
            return XCTFail("Expected .invalid(.error), got \(result)")
        }
        guard case .insufficientFunds = error else {
            return XCTFail("Expected .insufficientFunds, got \(error)")
        }
    }

    func test_validate_amountPlusFeeExceedsMax_returnsAmountError() throws {
        let sut = SufficientFundsValidator()
        let amount = Amount.max
        let gasPrice = try GasPrice(li: 1_000_000)
        let gasLimit = GasLimit.minimum
        let balance = Amount.max

        let result = sut.validate(input: (amount: amount, gasLimit: gasLimit, gasPrice: gasPrice, balance: balance))

        guard case let .invalid(.error(error)) = result else {
            return XCTFail("Expected .invalid(.error), got \(result)")
        }
        guard case .amountError = error else {
            return XCTFail("Expected .amountError, got \(error)")
        }
    }
}
