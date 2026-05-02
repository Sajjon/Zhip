@testable import AppFeature
import UIKit
import XCTest

@MainActor
final class ScrollableContentSizedTextViewTests: XCTestCase {
    func test_init_createsTextView() {
        let sut = ScrollableContentSizedTextView()
        XCTAssertNotNil(sut)
    }

    func test_intrinsicContentSize_widthIsNoIntrinsicMetric() {
        let sut = ScrollableContentSizedTextView()
        XCTAssertEqual(sut.intrinsicContentSize.width, UIView.noIntrinsicMetric)
    }

    func test_intrinsicContentSize_heightMatchesContentSize() {
        let sut = ScrollableContentSizedTextView()
        sut.frame = CGRect(x: 0, y: 0, width: 320, height: 100)
        sut.text = "Some text"
        sut.layoutIfNeeded()
        XCTAssertEqual(sut.intrinsicContentSize.height, sut.contentSize.height)
    }

    func test_setContentSize_invalidatesIntrinsicContentSize() {
        let sut = ScrollableContentSizedTextView()
        sut.frame = CGRect(x: 0, y: 0, width: 320, height: 100)
        sut.text = "Long text \nwith multiple\nlines\nfor content size"
        sut.layoutIfNeeded()
        XCTAssertGreaterThan(sut.intrinsicContentSize.height, 0)
    }
}
