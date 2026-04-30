import XCTest
import Zesame
@testable import AppFeature

final class GasPriceValidatorTests: XCTestCase {
    private let sut = GasPriceValidator()

    func test_validate_nonNumericString_returnsInvalid() {
        guard case .invalid = sut.validate(input: "not a number") else {
            return XCTFail("expected invalid")
        }
    }

    func test_validate_emptyString_returnsInvalid() {
        guard case .invalid = sut.validate(input: "") else {
            return XCTFail("expected invalid")
        }
    }

    func test_validate_negative_returnsInvalid() {
        guard case .invalid = sut.validate(input: "-1") else {
            return XCTFail("expected invalid")
        }
    }
}
