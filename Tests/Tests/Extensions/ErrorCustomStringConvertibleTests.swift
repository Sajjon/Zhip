//
// MIT License
//
// Copyright (c) 2018-2026 Open Zesame (https://github.com/OpenZesame)
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

/// Exercises the default `description` provided for enum-based `Error` types
/// conforming to `CustomStringConvertible` via mirror reflection.
final class ErrorCustomStringConvertibleTests: XCTestCase {
    private enum SampleEnumError: Swift.Error, CustomStringConvertible {
        case invalid(reason: String)
        case missingArgument(String)
    }

    func test_description_forEnumWithAssociatedValue_returnsCaseName() {
        let error: SampleEnumError = .invalid(reason: "oops")

        // The reflection helper extracts the outer case name.
        XCTAssertEqual(error.description, "invalid")
    }

    func test_description_forEnumWithUnlabelledAssociatedValue_returnsCaseName() {
        let error: SampleEnumError = .missingArgument("foo")

        XCTAssertEqual(error.description, "missingArgument")
    }
}
