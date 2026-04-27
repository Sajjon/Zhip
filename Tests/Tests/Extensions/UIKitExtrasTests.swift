import UIKit
import XCTest
@testable import Zhip

@MainActor
final class UIKitExtrasTests: XCTestCase {
    // MARK: - UITabBarItem convenience init

    func test_uiTabBarItem_titleOnlyInit_setsTitle() {
        let item = UITabBarItem("Home")
        XCTAssertEqual(item.title, "Home")
        XCTAssertNil(item.image)
        XCTAssertNil(item.selectedImage)
    }

    // MARK: - UINavigationController tabBar init

    func test_uiNavigationController_tabBarTitleInit_setsTabBarItemTitle() {
        let sut = UINavigationController(tabBarTitle: "Wallet")
        XCTAssertEqual(sut.tabBarItem.title, "Wallet")
    }

    // MARK: - UIScrollView.isContentOffsetNearBottom

    func test_isContentOffsetNearBottom_zeroOffsetReturnsFalse() {
        let sut = UIScrollView()
        sut.frame = CGRect(x: 0, y: 0, width: 100, height: 200)
        sut.contentSize = CGSize(width: 100, height: 1000)
        sut.contentOffset = .zero
        XCTAssertFalse(sut.isContentOffsetNearBottom())
    }

    func test_isContentOffsetNearBottom_smallContentSizeReturnsFalse() {
        let sut = UIScrollView()
        sut.frame = CGRect(x: 0, y: 0, width: 100, height: 200)
        sut.contentSize = CGSize(width: 100, height: 10)
        sut.contentOffset = CGPoint(x: 0, y: 5)
        XCTAssertFalse(sut.isContentOffsetNearBottom())
    }

    func test_isContentOffsetNearBottom_nearBottomReturnsTrue() {
        let sut = UIScrollView()
        sut.frame = CGRect(x: 0, y: 0, width: 100, height: 200)
        sut.contentSize = CGSize(width: 100, height: 1000)
        sut.contentOffset = CGPoint(x: 0, y: 790)
        XCTAssertTrue(sut.isContentOffsetNearBottom())
    }

    func test_isContentOffsetNearBottom_awayFromBottomReturnsFalse() {
        let sut = UIScrollView()
        sut.frame = CGRect(x: 0, y: 0, width: 100, height: 200)
        sut.contentSize = CGSize(width: 100, height: 1000)
        sut.contentOffset = CGPoint(x: 0, y: 100)
        XCTAssertFalse(sut.isContentOffsetNearBottom())
    }

    // MARK: - UserDefaults.deleteValue

    func test_userDefaults_deleteValue_removesObject() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "UIKitExtrasTests_userDefaults"))
        defaults.removePersistentDomain(forName: "UIKitExtrasTests_userDefaults")
        defaults.save(value: "stored", for: "testKey")
        XCTAssertNotNil(defaults.loadValue(for: "testKey"))

        defaults.deleteValue(for: "testKey")

        XCTAssertNil(defaults.loadValue(for: "testKey"))
    }
}
