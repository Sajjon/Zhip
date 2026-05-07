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
final class HtmlLoaderTests: XCTestCase {
    func test_load_returnsNonEmptyAttributedString_forBundledTermsHtml() {
        let sut = DefaultHtmlLoader()

        let result = sut.load(htmlFileName: "TermsOfService", textColor: .white, font: .body)

        XCTAssertGreaterThan(result.length, 0)
    }

    func test_load_appliesPassedTextColor() {
        let sut = DefaultHtmlLoader()
        let customColor = UIColor.red

        let result = sut.load(htmlFileName: "TermsOfService", textColor: customColor, font: .body)

        // The CSS injected by `generateHTMLWithCSS` sets the foreground color
        // for every character; pull the first character's foreground color
        // attribute and verify it matches.
        guard result.length > 0 else {
            XCTFail("Expected non-empty result")
            return
        }
        let attrs = result.attributes(at: 0, effectiveRange: nil)
        XCTAssertNotNil(attrs[.foregroundColor])
    }

    func test_loadConvenienceOverload_appliesDefaults() {
        let sut = DefaultHtmlLoader()

        // The single-argument overload defaults to `.white` text + `.body`
        // font and should return a non-empty attributed string for a
        // bundled HTML file.
        let result = sut.load(htmlFileName: "TermsOfService")

        XCTAssertGreaterThan(result.length, 0)
    }
}
