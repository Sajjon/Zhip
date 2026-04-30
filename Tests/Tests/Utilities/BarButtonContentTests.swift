import SingleLineControllerController
import UIKit
import XCTest
@testable import AppFeature

final class BarButtonContentTests: XCTestCase {
    func test_initWithTitle_storesTextTypeAndPlainStyle() {
        let sut = BarButtonContent(title: "Cancel")
        if case let .text(text) = sut.type {
            XCTAssertEqual(text, "Cancel")
        } else {
            XCTFail("expected .text")
        }
        XCTAssertEqual(sut.style, .plain)
    }

    func test_initWithSystem_storesSystemType_andHasNilStyle() {
        let sut = BarButtonContent(system: .close)
        if case let .system(item) = sut.type {
            XCTAssertEqual(item, .close)
        } else {
            XCTFail("expected .system")
        }
    }

    func test_makeBarButtonItem_fromText_producesUIBarButtonItemWithTitle() {
        let sut = BarButtonContent(title: "Skip")
        let item = sut.makeBarButtonItem(target: nil, selector: #selector(noop))
        XCTAssertEqual(item.title, "Skip")
    }

    func test_makeBarButtonItem_fromSystem_producesUIBarButtonItem() {
        let sut = BarButtonContent(system: .done)
        let item = sut.makeBarButtonItem(target: nil, selector: #selector(noop))
        XCTAssertNotNil(item)
    }

    @objc private func noop() {}
}
