import UIKit
import XCTest
@testable import AppFeature

private struct TestPair: Mergeable {
    var a: String?
    var b: String?

    func merged(other: TestPair, mode: MergeMode) -> TestPair {
        TestPair(
            a: mergeAttribute(other: other, path: \.a, mode: mode),
            b: mergeAttribute(other: other, path: \.b, mode: mode)
        )
    }
}

final class MergeableTests: XCTestCase {
    func test_mergeYieldingTo_picksOtherWhenSet() {
        let lhs = TestPair(a: "left", b: nil)
        let rhs = TestPair(a: "right", b: "rhsB")

        let result = lhs.merge(yieldingTo: rhs)

        XCTAssertEqual(result.a, "right")
        XCTAssertEqual(result.b, "rhsB")
    }

    func test_mergeYieldingTo_fallsBackToSelfWhenOtherNil() {
        let lhs = TestPair(a: "left", b: "leftB")
        let rhs = TestPair(a: nil, b: nil)

        let result = lhs.merge(yieldingTo: rhs)

        XCTAssertEqual(result.a, "left")
        XCTAssertEqual(result.b, "leftB")
    }

    func test_mergeYieldingToOptional_returnsSelfWhenOtherIsNil() {
        let lhs = TestPair(a: "left", b: "leftB")

        let result = lhs.merge(yieldingTo: TestPair?.none)

        XCTAssertEqual(result.a, "left")
        XCTAssertEqual(result.b, "leftB")
    }

    func test_mergeYieldingToOptional_mergesWhenOtherProvided() {
        let lhs = TestPair(a: "left", b: nil)
        let rhs: TestPair? = TestPair(a: "right", b: "rhsB")

        let result = lhs.merge(yieldingTo: rhs)

        XCTAssertEqual(result.a, "right")
        XCTAssertEqual(result.b, "rhsB")
    }

    func test_mergeOverridingOther_prefersSelfWhenSet() {
        let lhs = TestPair(a: "left", b: nil)
        let rhs = TestPair(a: "right", b: "rhsB")

        let result = lhs.merge(overridingOther: rhs)

        XCTAssertEqual(result.a, "left")
        XCTAssertEqual(result.b, "rhsB")
    }

    func test_mergeOverridingOtherOptional_returnsSelfWhenOtherNil() {
        let lhs = TestPair(a: "left", b: "leftB")

        let result = lhs.merge(overridingOther: TestPair?.none)

        XCTAssertEqual(result.a, "left")
        XCTAssertEqual(result.b, "leftB")
    }

    func test_mergeOverridingOtherOptional_mergesWhenOtherProvided() {
        let lhs = TestPair(a: nil, b: "leftB")
        let rhs: TestPair? = TestPair(a: "right", b: "rhsB")

        let result = lhs.merge(overridingOther: rhs)

        XCTAssertEqual(result.a, "right")
        XCTAssertEqual(result.b, "leftB")
    }

    func test_optionalMergeYieldingTo_selfNil_returnsOther() {
        let lhs: TestPair? = nil
        let rhs = TestPair(a: "right", b: "rhsB")

        let result = lhs.merge(yieldingTo: rhs)

        XCTAssertEqual(result.a, "right")
        XCTAssertEqual(result.b, "rhsB")
    }

    func test_optionalMergeYieldingTo_selfSet_mergesYieldingToOther() {
        let lhs: TestPair? = TestPair(a: "left", b: nil)
        let rhs = TestPair(a: "right", b: "rhsB")

        let result = lhs.merge(yieldingTo: rhs)

        XCTAssertEqual(result.a, "right")
        XCTAssertEqual(result.b, "rhsB")
    }

    func test_optionalMergeOverridingOther_selfNil_returnsOther() {
        let lhs: TestPair? = nil
        let rhs = TestPair(a: "right", b: "rhsB")

        let result = lhs.merge(overridingOther: rhs)

        XCTAssertEqual(result.a, "right")
        XCTAssertEqual(result.b, "rhsB")
    }

    func test_optionalMergeOverridingOther_selfSet_mergesOverriding() {
        let lhs: TestPair? = TestPair(a: "left", b: nil)
        let rhs = TestPair(a: "right", b: "rhsB")

        let result = lhs.merge(overridingOther: rhs)

        XCTAssertEqual(result.a, "left")
        XCTAssertEqual(result.b, "rhsB")
    }
}
