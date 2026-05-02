@testable import AppFeature
import XCTest

final class BundleVersionBuildTests: XCTestCase {
    func test_key_shortVersionString_formsCFBundleKey() {
        XCTAssertEqual(Bundle.Key.shortVersionString.key, "CFBundleShortVersionString")
    }

    func test_key_version_formsCFBundleKey() {
        XCTAssertEqual(Bundle.Key.version.key, "CFBundleVersion")
    }

    func test_key_name_formsCFBundleKey() {
        XCTAssertEqual(Bundle.Key.name.key, "CFBundleName")
    }

    func test_capitalizingFirstLetter_lowercaseWord() {
        XCTAssertEqual("hello".capitalizingFirstLetter(), "Hello")
    }

    func test_capitalizingFirstLetter_alreadyCapitalized_isUnchanged() {
        XCTAssertEqual("World".capitalizingFirstLetter(), "World")
    }

    func test_capitalizingFirstLetter_emptyString_remainsEmpty() {
        XCTAssertEqual("".capitalizingFirstLetter(), "")
    }

    func test_capitalizeFirstLetter_mutatesInPlace() {
        var s = "abc"
        s.capitalizeFirstLetter()
        XCTAssertEqual(s, "Abc")
    }

    func test_bundle_value_ofUnknownKey_returnsNil() {
        let bundle = Bundle(for: BundleVersionBuildTests.self)
        XCTAssertNil(bundle.value(of: "SomeNonsenseKey_XYZ"))
    }
}
