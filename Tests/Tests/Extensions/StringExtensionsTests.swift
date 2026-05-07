//
// MIT License
//
// Copyright (c) 2018-2026 Alexander Cyon (https://github.com/sajjon)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

@testable import AppFeature
import UIKit
import XCTest

@MainActor
final class StringExtensionsTests: XCTestCase {
    // MARK: - inserting(string:every:)

    func test_insertingEvery_groupsFromTheEnd() {
        XCTAssertEqual("1234567".inserting(string: ",", every: 3), "1,234,567")
    }

    func test_insertingEvery_evenChunkBoundary_returnsCleanGrouping() {
        XCTAssertEqual("123456".inserting(string: ",", every: 3), "123,456")
    }

    func test_insertingEvery_shorterThanInterval_returnsUnchanged() {
        XCTAssertEqual("12".inserting(string: ",", every: 3), "12")
    }

    func test_insertingEvery_exactlyIntervalLength_returnsUnchanged() {
        // `count > interval` is the guard, so equal length should pass through.
        XCTAssertEqual("123".inserting(string: ",", every: 3), "123")
    }

    func test_insertingEvery_emptyString_returnsEmpty() {
        XCTAssertEqual("".inserting(string: ",", every: 3), "")
    }

    func test_insertingEvery_acceptsMultiCharSeparator() {
        XCTAssertEqual("1234567".inserting(string: " | ", every: 3), "1 | 234 | 567")
    }

    // MARK: - droppingLast

    func test_droppingLast_validCount_popsTailAndReturnsIt() {
        var s = "abcdef"

        let dropped = s.droppingLast(2)

        XCTAssertEqual(dropped, "ef")
        XCTAssertEqual(s, "abcd")
    }

    func test_droppingLast_zero_returnsEmptyAndLeavesStringUnchanged() {
        var s = "abc"

        let dropped = s.droppingLast(0)

        XCTAssertEqual(dropped, "")
        XCTAssertEqual(s, "abc")
    }

    func test_droppingLast_tooMany_returnsNilAndLeavesStringUnchanged() {
        var s = "abc"

        let dropped = s.droppingLast(10)

        XCTAssertNil(dropped)
        XCTAssertEqual(s, "abc")
    }

    // MARK: - sizeUsingFont / widthUsingFont

    func test_sizeUsingFont_returnsNonZeroSizeForNonEmptyString() {
        let size = "hello".sizeUsingFont(UIFont.systemFont(ofSize: 17))

        XCTAssertGreaterThan(size.width, 0)
        XCTAssertGreaterThan(size.height, 0)
    }

    func test_widthUsingFont_returnsSameWidthAsSize() {
        let font = UIFont.systemFont(ofSize: 17)
        let s = "hello"

        XCTAssertEqual(s.widthUsingFont(font), s.sizeUsingFont(font).width, accuracy: 0.001)
    }
}
