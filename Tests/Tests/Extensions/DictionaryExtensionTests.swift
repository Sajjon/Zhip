import XCTest
@testable import AppFeature

final class DictionaryExtensionTests: XCTestCase {
    func test_compactMapValues_dropsNilResults() {
        let input = ["a": "1", "b": "two", "c": "3"]
        let result = input.compactMapValues { Int($0) }
        XCTAssertEqual(result, ["a": 1, "c": 3])
    }

    func test_compactMapValues_emptyInput_returnsEmpty() {
        let input: [String: String] = [:]
        let result = input.compactMapValues { Int($0) }
        XCTAssertTrue(result.isEmpty)
    }

    func test_compactMapValues_allValid_preservesAllKeys() {
        let input = ["a": "1", "b": "2"]
        let result = input.compactMapValues { Int($0) }
        XCTAssertEqual(result, ["a": 1, "b": 2])
    }
}
