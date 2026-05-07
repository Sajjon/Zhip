//
// MIT License
//
// Copyright (c) 2018-2019 Alexander Cyon (https://github.com/sajjon)
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
import Foundation
import UIKit
import XCTest

class StringFormattingTests: XCTestCase {
    func testFormatting() {
        func f(_ s: String) -> String {
            s.inserting(string: "x", every: 3)
        }

        XCTAssertEqual(f("1"), "1")
        XCTAssertEqual(f("12"), "12")
        XCTAssertEqual(f("123"), "123")
        XCTAssertEqual(f("1234"), "1x234")
        XCTAssertEqual(f("12345"), "12x345")
        XCTAssertEqual(f("123456"), "123x456")
        XCTAssertEqual(f("1234567"), "1x234x567")
        XCTAssertEqual(f("12345678"), "12x345x678")
        XCTAssertEqual(f("123456789"), "123x456x789")
        XCTAssertEqual(f("123456789a"), "1x234x567x89a")
    }

    /// Exercises the `hasSuffix(" ")` drop-last branch of `String.thousands` —
    /// reachable when the input already ends in a space, which causes the
    /// `inserting(string: " ", every: 3)` helper to leave a trailing separator.
    func test_thousands_whenResultingStringEndsWithSpace_dropsTrailingSpace() {
        let result = "abc def ".thousands
        XCTAssertFalse(result.hasSuffix(" "))
        XCTAssertEqual(result, "ab c d ef")
    }

    func test_thousands_whenNoGrouping_returnsUnchanged() {
        XCTAssertEqual("12".thousands, "12")
    }

    func test_containsOnlyDecimalNumbers_allDigits_returnsTrue() {
        XCTAssertTrue("12345".containsOnlyDecimalNumbers())
    }

    func test_containsOnlyDecimalNumbers_withLetter_returnsFalse() {
        XCTAssertFalse("12a45".containsOnlyDecimalNumbers())
    }

    func test_containsOnlyDecimalNumbers_emptyString_returnsTrue() {
        XCTAssertTrue("".containsOnlyDecimalNumbers())
    }
}
