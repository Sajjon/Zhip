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
import XCTest

/// Exercises `findNestedEnumOfType(_:in:recursiveTriesLeft:)`, a reflection
/// helper used to extract nested enum case names for `Error` descriptions.
@MainActor
final class EnumReflectionTests: XCTestCase {
    enum Outer {
        case wrapping(Inner)
        case direct
    }

    enum Inner {
        case first
        case second
    }

    func test_findNestedEnumOfType_returnsNestedCase() {
        let outer = Outer.wrapping(.first)

        let inner = findNestedEnumOfType(Inner.self, in: outer, recursiveTriesLeft: 3)

        XCTAssertEqual(inner, .first)
    }

    func test_findNestedEnumOfType_returnsNilForNonEnumInput() {
        struct NotAnEnum {
            let value = 1
        }

        let result = findNestedEnumOfType(Inner.self, in: NotAnEnum(), recursiveTriesLeft: 3)

        XCTAssertNil(result)
    }

    func test_findNestedEnumOfType_returnsNilWhenRecursiveTriesExhausted() {
        let outer = Outer.direct

        let result = findNestedEnumOfType(Inner.self, in: outer, recursiveTriesLeft: -1)

        XCTAssertNil(result)
    }
}
