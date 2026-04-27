//
// MIT License
//
// Copyright (c) 2018-2026 Open Zesame (https://github.com/OpenZesame)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import Combine
import SingleLineControllerCore
import UIKit
import XCTest
@testable import Zhip

final class PincodeTextFieldTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - init / basic configuration

    func test_init_setsSecureNumberPadAndClearColors() {
        let sut = PincodeTextField()

        XCTAssertEqual(sut.keyboardType, .numberPad)
        XCTAssertTrue(sut.isSecureTextEntry)
        XCTAssertEqual(sut.textColor, .clear)
        XCTAssertEqual(sut.tintColor, .clear)
    }

    func test_initFromCoder_triggersInterfaceBuilderSucks_isNotCalled() {
        // No direct test — the required init is intentionally unreachable; documented as interfaceBuilderSucks.
        // We simply verify the standard init completes without crash to match the public contract.
        _ = PincodeTextField()
    }

    // MARK: - canPerformAction — disables edit-menu actions

    func test_canPerformAction_disablesPaste() {
        let sut = PincodeTextField()

        XCTAssertFalse(sut.canPerformAction(#selector(UIResponderStandardEditActions.paste(_:)), withSender: nil))
    }

    func test_canPerformAction_disablesCopy() {
        let sut = PincodeTextField()

        XCTAssertFalse(sut.canPerformAction(#selector(UIResponderStandardEditActions.copy(_:)), withSender: nil))
    }

    func test_canPerformAction_disablesCut() {
        let sut = PincodeTextField()

        XCTAssertFalse(sut.canPerformAction(#selector(UIResponderStandardEditActions.cut(_:)), withSender: nil))
    }

    func test_canPerformAction_disablesSelectAll() {
        let sut = PincodeTextField()

        XCTAssertFalse(sut.canPerformAction(#selector(UIResponderStandardEditActions.selectAll(_:)), withSender: nil))
    }

    func test_canPerformAction_disablesSelect() {
        let sut = PincodeTextField()

        XCTAssertFalse(sut.canPerformAction(#selector(UIResponderStandardEditActions.select(_:)), withSender: nil))
    }

    func test_canPerformAction_disablesDelete() {
        let sut = PincodeTextField()

        XCTAssertFalse(sut.canPerformAction(#selector(UIResponderStandardEditActions.delete(_:)), withSender: nil))
    }

    // MARK: - gesture handling

    func test_addGestureRecognizer_disablesLongPress() {
        let sut = PincodeTextField()
        let longPress = UILongPressGestureRecognizer()

        sut.addGestureRecognizer(longPress)

        XCTAssertFalse(longPress.isEnabled)
    }

    func test_addGestureRecognizer_leavesOtherRecognizersEnabled() {
        let sut = PincodeTextField()
        let tap = UITapGestureRecognizer()

        sut.addGestureRecognizer(tap)

        XCTAssertTrue(tap.isEnabled)
    }

    func test_gestureRecognizerShouldBegin_longPressWithoutDelaysTouchesEnded_returnsFalse() {
        let sut = PincodeTextField()
        let longPress = UILongPressGestureRecognizer()
        longPress.delaysTouchesEnded = false

        XCTAssertFalse(sut.gestureRecognizerShouldBegin(longPress))
    }

    func test_gestureRecognizerShouldBegin_longPressWithDelaysTouchesEnded_returnsTrue() {
        let sut = PincodeTextField()
        let longPress = UILongPressGestureRecognizer()
        longPress.delaysTouchesEnded = true

        XCTAssertTrue(sut.gestureRecognizerShouldBegin(longPress))
    }

    func test_gestureRecognizerShouldBegin_otherRecognizer_returnsTrue() {
        let sut = PincodeTextField()
        let tap = UITapGestureRecognizer()

        XCTAssertTrue(sut.gestureRecognizerShouldBegin(tap))
    }

    // MARK: - setPincode / clearInput / pincodePublisher

    func test_setPincode_thenClearInput_doesNotCrash() throws {
        let sut = PincodeTextField()
        let pincode = try Pincode(digits: [.one, .two, .three, .four])

        sut.setPincode(pincode)
        sut.clearInput()

        XCTAssertTrue(sut.text?.isEmpty ?? true)
    }

    func test_validate_errorMessage_doesNotCrash() {
        let sut = PincodeTextField()

        sut.applyValidation(.errorMessage("oops"))
    }

    func test_validate_valid_doesNotCrash() {
        let sut = PincodeTextField()

        sut.applyValidation(.valid(withRemark: nil))
    }

    func test_validate_empty_doesNotCrash() {
        let sut = PincodeTextField()

        sut.applyValidation(.empty)
    }

    func test_pincodePublisher_emitsNilWhenSettingShorterInput() {
        let sut = PincodeTextField()
        var received: [Pincode?] = []
        sut.pincodePublisher.sink { received.append($0) }.store(in: &cancellables)

        sut.text = "12"
        NotificationCenter.default.post(name: UITextField.textDidChangeNotification, object: sut)

        XCTAssertTrue(received.contains(where: { $0 == nil }))
    }

    func test_pincodePublisher_emitsPincodeWhenFullLengthTyped() {
        let sut = PincodeTextField()
        var received: [Pincode?] = []
        sut.pincodePublisher.sink { received.append($0) }.store(in: &cancellables)

        sut.text = String(repeating: "0", count: Pincode.length)
        NotificationCenter.default.post(name: UITextField.textDidChangeNotification, object: sut)

        XCTAssertTrue(received.contains(where: { $0 != nil }))
    }
}

// MARK: - String.isBackspace

final class StringIsBackspaceTests: XCTestCase {
    func test_nonBackspaceString_isNotBackspace() {
        XCTAssertFalse("abc".isBackspace)
    }
}
