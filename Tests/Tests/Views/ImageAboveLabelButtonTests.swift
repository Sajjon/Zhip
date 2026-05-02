@testable import AppFeature
import UIKit
import XCTest

@MainActor
final class ImageAboveLabelButtonTests: XCTestCase {
    func test_init_createsButton() {
        let sut = ImageAboveLabelButton()
        XCTAssertFalse(sut.translatesAutoresizingMaskIntoConstraints)
    }

    func test_setTitle_image_doesNotCrashOnLayout() {
        let sut = ImageAboveLabelButton()
        let image = UIImage()
        sut.setTitle("Send", image: image)
        sut.frame = CGRect(x: 0, y: 0, width: 200, height: 80)
        sut.layoutIfNeeded()
    }

    func test_accessibilityLabel_isForwardedToCustomLabel() {
        let sut = ImageAboveLabelButton()
        sut.setTitle("Send", image: UIImage())
        sut.accessibilityLabel = "Send button"
        XCTAssertEqual(sut.accessibilityLabel, "Send button")
    }

    func test_accessibilityHint_isForwardedToCustomLabel() {
        let sut = ImageAboveLabelButton()
        sut.setTitle("Send", image: UIImage())
        sut.accessibilityHint = "Sends the transaction"
        XCTAssertEqual(sut.accessibilityHint, "Sends the transaction")
    }

    func test_accessibilityValue_isForwardedToCustomLabel() {
        let sut = ImageAboveLabelButton()
        sut.setTitle("Send", image: UIImage())
        sut.accessibilityValue = "0 ZIL"
        XCTAssertEqual(sut.accessibilityValue, "0 ZIL")
    }
}
