@testable import AppFeature
import XCTest

final class PincodeDigitTests: XCTestCase {
    // MARK: - Digit(string:)

    func test_digit_fromString_zeroToNine_allInitialize() {
        for i in 0 ... 9 {
            XCTAssertEqual(Digit(string: String(i))?.rawValue, i, "failed for \(i)")
        }
    }

    func test_digit_fromString_outOfRange_returnsNil() {
        XCTAssertNil(Digit(string: "10"))
        XCTAssertNil(Digit(string: "-1"))
    }

    func test_digit_fromString_nonNumeric_returnsNil() {
        XCTAssertNil(Digit(string: "x"))
        XCTAssertNil(Digit(string: ""))
    }

    func test_digit_description_matchesRawValue() {
        XCTAssertEqual(Digit.zero.description, "0")
        XCTAssertEqual(Digit.five.description, "5")
        XCTAssertEqual(Digit.nine.description, "9")
    }

    // MARK: - Pincode(digits:)

    func test_pincode_initWithCorrectLength_succeeds() throws {
        let pin = try Pincode(digits: [.one, .two, .three, .four])
        XCTAssertEqual(pin.digits, [.one, .two, .three, .four])
    }

    func test_pincode_initWithTooFewDigits_throwsTooShort() {
        XCTAssertThrowsError(try Pincode(digits: [.one, .two])) { error in
            XCTAssertEqual(error as? Pincode.Error, .pincodeTooShort)
        }
    }

    func test_pincode_initWithTooManyDigits_throwsTooLong() {
        XCTAssertThrowsError(try Pincode(digits: [.one, .two, .three, .four, .five])) { error in
            XCTAssertEqual(error as? Pincode.Error, .pincodeTooLong)
        }
    }

    func test_pincode_length_is4() {
        XCTAssertEqual(Pincode.length, 4)
    }

    func test_pincode_equatable_sameDigits_areEqual() throws {
        let a = try Pincode(digits: [.zero, .one, .two, .three])
        let b = try Pincode(digits: [.zero, .one, .two, .three])
        XCTAssertEqual(a, b)
    }

    func test_pincode_equatable_differentDigits_notEqual() throws {
        let a = try Pincode(digits: [.zero, .one, .two, .three])
        let b = try Pincode(digits: [.zero, .one, .two, .four])
        XCTAssertNotEqual(a, b)
    }

    func test_pincode_codable_roundtrips() throws {
        let original = try Pincode(digits: [.nine, .eight, .seven, .six])
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Pincode.self, from: data)
        XCTAssertEqual(decoded, original)
    }
}
