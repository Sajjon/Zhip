@testable import AppFeature
import XCTest

final class EncodableDictionaryTests: XCTestCase {
    private struct SimpleEncodable: Encodable {
        let name: String
        let count: Int
    }

    func test_dictionaryRepresentation_encodesStringAndIntFields() {
        let sut = SimpleEncodable(name: "alice", count: 3)
        let result = sut.dictionaryRepresentation
        XCTAssertEqual(result["name"] as? String, "alice")
        XCTAssertEqual(result["count"] as? Int, 3)
    }

    func test_dictionaryRepresentation_emptyEncodable_returnsEmptyOrExpectedKeys() {
        struct Empty: Encodable {}
        let sut = Empty()
        let result = sut.dictionaryRepresentation
        XCTAssertTrue(result.isEmpty)
    }

    /// Forces the `encode(to:)` throw path by using an encoder that rejects the type.
    private struct ThrowingOnEncode: Encodable {
        struct BadError: Error {}
        func encode(to _: Encoder) throws {
            throw BadError()
        }
    }

    func test_dictionaryRepresentation_whenEncodeThrows_returnsEmptyDictionary() {
        let sut = ThrowingOnEncode()
        XCTAssertTrue(sut.dictionaryRepresentation.isEmpty)
    }
}
