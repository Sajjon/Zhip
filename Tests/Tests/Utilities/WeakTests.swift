@testable import AppFeature
import XCTest

final class WeakTests: XCTestCase {
    func test_weak_holdsValueWhileObjectLives() {
        let obj = DummyClass(value: 42)
        let sut = Weak(obj)
        XCTAssertNotNil(sut.value)
        XCTAssertEqual(sut.value?.value, 42)
    }

    func test_weak_releasesWhenObjectDeallocates() throws {
        var obj: DummyClass? = DummyClass(value: 1)
        let sut = try Weak(XCTUnwrap(obj))
        obj = nil
        XCTAssertNil(sut.value)
    }
}

private final class DummyClass {
    let value: Int
    init(value: Int) {
        self.value = value
    }
}
