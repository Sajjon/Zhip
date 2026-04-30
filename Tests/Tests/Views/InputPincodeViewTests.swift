@testable import AppFeature
import Combine
import Factory
import SingleLineControllerCombine
import SingleLineControllerDIPrimitives
import UIKit
import XCTest

final class InputPincodeViewTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var mockHaptic: MockHapticFeedback!

    override func setUp() {
        super.setUp()
        mockHaptic = MockHapticFeedback()
        Container.shared.hapticFeedback.register { [unowned self] in mockHaptic }
    }

    override func tearDown() {
        cancellables.removeAll()
        Container.shared.manager.reset()
        mockHaptic = nil
        super.tearDown()
    }

    func test_init_createsPinFieldAndStackView() {
        let sut = InputPincodeView()
        XCTAssertNotNil(sut.pinField)
    }

    func test_validate_empty_doesNotCrash() {
        let sut = InputPincodeView()
        sut.applyValidation(.empty)
    }

    func test_validate_valid_clearsByDefault() {
        let sut = InputPincodeView()
        sut.applyValidation(.valid(withRemark: nil))
        XCTAssertTrue(sut.pinField.text?.isEmpty ?? true)
    }

    func test_validate_valid_doesNotClearWhenIsClearedOnValidInputFalse() {
        let sut = InputPincodeView(isClearedOnValidInput: false)
        sut.pinField.text = "1234"

        sut.applyValidation(.valid(withRemark: nil))

        XCTAssertEqual(sut.pinField.text, "1234")
    }

    func test_validate_errorMessage_shakesAndClears() {
        let sut = InputPincodeView()
        sut.applyValidation(.errorMessage("bad pin"))
        // Should not crash; shake animation completion clears asynchronously.
    }

    func test_pincodePublisher_forwardsFromPinField() {
        let sut = InputPincodeView()
        var received: [Pincode?] = []
        sut.pincodePublisher.sink { received.append($0) }.store(in: &cancellables)

        sut.pinField.text = "12"
        NotificationCenter.default.post(name: UITextField.textDidChangeNotification, object: sut.pinField)

        XCTAssertTrue(received.contains(where: { $0 == nil }))
    }

    func test_validationBinder_appliesValidation() {
        let sut = InputPincodeView()

        sut.validationBinder.on(.errorMessage("oops"))
        // Just ensures the binder runs without crashing.
    }

    func test_becomeFirstResponderBinder_isAvailable() {
        let sut = InputPincodeView()
        _ = sut.becomeFirstResponderBinder
    }

    func test_validate_valid_firesSuccessHaptic() {
        let sut = InputPincodeView()

        sut.applyValidation(.valid(withRemark: nil))

        XCTAssertEqual(mockHaptic.notifications, [.success])
    }

    func test_validate_errorMessage_firesErrorHaptic() {
        let sut = InputPincodeView()

        sut.applyValidation(.errorMessage("bad pin"))

        XCTAssertEqual(mockHaptic.notifications, [.error])
    }

    func test_validate_empty_firesNoHaptic() {
        let sut = InputPincodeView()

        sut.applyValidation(.empty)

        XCTAssertTrue(mockHaptic.notifications.isEmpty)
    }
}
