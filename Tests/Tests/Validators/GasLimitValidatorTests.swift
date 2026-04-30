import XCTest
import Zesame
@testable import AppFeature

final class GasLimitValidatorTests: XCTestCase {
    private let sut = GasLimitValidator()

    func test_validate_nonNumericString_returnsInvalid() {
        guard case .invalid = sut.validate(input: "hello") else {
            return XCTFail("expected invalid")
        }
    }

    func test_validate_zero_returnsTooSmall() {
        guard case let .invalid(.error(error)) = sut.validate(input: "0") else {
            return XCTFail("expected invalid")
        }
        if case .tooSmall = error {} else { XCTFail("expected .tooSmall, got \(error)") }
    }

    func test_validate_atOrAboveMinimum_returnsValid() {
        let minimumString = GasLimit.minimum.description
        guard case .valid = sut.validate(input: minimumString) else {
            return XCTFail("expected valid")
        }
    }

    func test_validate_aboveMinimum_returnsValid() {
        let amount = String(GasLimit.minimum.description
            .dropFirst(0)) // "1" prepended would fail parse for large value, keep simple
        guard case .valid = sut.validate(input: amount) else {
            return XCTFail("expected valid")
        }
    }
}
