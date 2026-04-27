import SingleLineControllerCombine
import XCTest
@testable import Zhip

final class ArrayExtensionTests: XCTestCase {
    func test_mapToVoid_emptyArray_returnsEmpty() {
        let result: [Void] = [Int]().mapToVoid()
        XCTAssertEqual(result.count, 0)
    }

    func test_mapToVoid_preservesCount() {
        let result: [Void] = [1, 2, 3, 4, 5].mapToVoid()
        XCTAssertEqual(result.count, 5)
    }

    func test_plusEquals_appendsElement() {
        var array = [1, 2, 3]
        array += 4
        XCTAssertEqual(array, [1, 2, 3, 4])
    }

    func test_plusEquals_emptyArray_appendsSingleElement() {
        var array: [String] = []
        array += "hello"
        XCTAssertEqual(array, ["hello"])
    }
}
