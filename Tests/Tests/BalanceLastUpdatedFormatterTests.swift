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

import XCTest
@testable import AppFeature

/// Tests for `BalanceLastUpdatedFormatter`: a pure formatter with no
/// dependencies, so each test is a one-liner.
final class BalanceLastUpdatedFormatterTests: XCTestCase {
    private let sut = BalanceLastUpdatedFormatter()

    func test_nilDate_returnsFirstFetchString() {
        // Act
        let result = sut.string(from: nil)

        // Assert
        XCTAssertFalse(result.isEmpty)
    }

    func test_knownDate_returnsNonEmptyRelativeString() {
        // Arrange
        let tenSecondsAgo = Date(timeIntervalSinceNow: -10)

        // Act
        let result = sut.string(from: tenSecondsAgo)

        // Assert
        XCTAssertFalse(result.isEmpty)
    }
}
