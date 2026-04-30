import UIKit
import XCTest
@testable import AppFeature

final class TextFieldDelegateTests: XCTestCase {
    func test_init_withTypeOfInput_setsLimitingCharacterSet() {
        let sut = TextFieldDelegate(type: .number, maxLength: 10)
        let textField = UITextField()

        let result = sut.textField(
            textField,
            shouldChangeCharactersIn: NSRange(location: 0, length: 0),
            replacementString: "abc"
        )

        XCTAssertFalse(result)
    }

    func test_shouldChangeCharacters_allowsBackspace() {
        let sut = TextFieldDelegate(type: .number, maxLength: 4)
        let textField = UITextField()
        textField.text = "1234"

        let result = sut.textField(
            textField,
            shouldChangeCharactersIn: NSRange(location: 3, length: 1),
            replacementString: ""
        )

        XCTAssertTrue(result)
    }

    func test_shouldChangeCharacters_allowsLegalCharacter() {
        let sut = TextFieldDelegate(type: .number, maxLength: 10)
        let textField = UITextField()
        textField.text = ""

        let result = sut.textField(
            textField,
            shouldChangeCharactersIn: NSRange(location: 0, length: 0),
            replacementString: "5"
        )

        XCTAssertTrue(result)
    }

    func test_shouldChangeCharacters_rejectsIllegalCharacter() {
        let sut = TextFieldDelegate(type: .number, maxLength: 10)
        let textField = UITextField()
        textField.text = ""

        let result = sut.textField(
            textField,
            shouldChangeCharactersIn: NSRange(location: 0, length: 0),
            replacementString: "z"
        )

        XCTAssertFalse(result)
    }

    func test_shouldChangeCharacters_rejectsWhenWouldExceedMaxLength() {
        let sut = TextFieldDelegate(type: .number, maxLength: 3)
        let textField = UITextField()
        textField.text = "123"

        let result = sut.textField(
            textField,
            shouldChangeCharactersIn: NSRange(location: 3, length: 0),
            replacementString: "4"
        )

        XCTAssertFalse(result)
    }

    func test_shouldChangeCharacters_allowsAtMaxLength() {
        let sut = TextFieldDelegate(type: .number, maxLength: 4)
        let textField = UITextField()
        textField.text = "123"

        let result = sut.textField(
            textField,
            shouldChangeCharactersIn: NSRange(location: 3, length: 0),
            replacementString: "4"
        )

        XCTAssertTrue(result)
    }

    func test_shouldChangeCharacters_noMaxLength_allowsArbitraryLength() {
        let sut = TextFieldDelegate(type: .text, maxLength: nil)
        let textField = UITextField()
        textField.text = String(repeating: "a", count: 1000)

        let result = sut.textField(
            textField,
            shouldChangeCharactersIn: NSRange(location: 1000, length: 0),
            replacementString: "b"
        )

        XCTAssertTrue(result)
    }

    func test_shouldChangeCharacters_noLimitingCharacterSet_allowsAnything() {
        let sut = TextFieldDelegate(type: .password, maxLength: 50)
        let textField = UITextField()

        let result = sut.textField(
            textField,
            shouldChangeCharactersIn: NSRange(location: 0, length: 0),
            replacementString: "!@#$%"
        )

        XCTAssertTrue(result)
    }

    func test_setTypeOfInput_changesAcceptanceCriteria() {
        let sut = TextFieldDelegate(type: .number, maxLength: 10)
        let textField = UITextField()
        textField.text = ""

        XCTAssertFalse(sut.textField(
            textField,
            shouldChangeCharactersIn: NSRange(location: 0, length: 0),
            replacementString: "ab"
        ))

        sut.setTypeOfInput(.text)

        XCTAssertTrue(sut.textField(
            textField,
            shouldChangeCharactersIn: NSRange(location: 0, length: 0),
            replacementString: "ab"
        ))
    }
}
