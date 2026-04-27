import UIKit
import XCTest
@testable import Zhip

final class UIColorExtensionTests: XCTestCase {
    func test_defaultText_isWhite() {
        XCTAssertEqual(UIColor.defaultText, .white)
    }

    func test_teal_hexString_isExpected() {
        XCTAssertEqual(UIColor.teal.hexString, "#00a88d")
    }

    func test_darkTeal_hexString_isExpected() {
        XCTAssertEqual(UIColor.darkTeal.hexString, "#0f675b")
    }

    func test_deepBlue_hexString_isExpected() {
        XCTAssertEqual(UIColor.deepBlue.hexString, "#1f292f")
    }

    func test_mellowYellow_hexString_isExpected() {
        XCTAssertEqual(UIColor.mellowYellow.hexString, "#ffd14c")
    }

    func test_bloodRed_hexString_isExpected() {
        XCTAssertEqual(UIColor.bloodRed.hexString, "#ff4c4f")
    }

    func test_asphaltGrey_hexString_isExpected() {
        XCTAssertEqual(UIColor.asphaltGrey.hexString, "#40484d")
    }

    func test_silverGrey_hexString_isExpected() {
        XCTAssertEqual(UIColor.silverGrey.hexString, "#6f7579")
    }

    func test_dusk_hexString_isExpected() {
        XCTAssertEqual(UIColor.dusk.hexString, "#192226")
    }

    func test_blackHexString_returnsBlackHex() {
        XCTAssertEqual(UIColor.black.hexString, "#000000")
    }

    func test_redHexString_returnsRedHex() {
        XCTAssertEqual(UIColor.red.hexString, "#ff0000")
    }
}
