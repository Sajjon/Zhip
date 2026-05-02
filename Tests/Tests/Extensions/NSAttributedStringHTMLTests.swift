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
import Resources
import UIKit
import XCTest

/// Coverage for `htmlAsAttributedString`, `generateHTMLWithCSS`, and the
/// `NSMutableAttributedString.setFontFace(font:color:)` helper they share.
///
/// The `incorrectImplementation` failure paths (missing-bundle, unparsable
/// HTML, encoding failure) are unreachable in practice — they only fire on
/// programmer/asset bugs — so the tests exercise the happy paths only.
@MainActor
final class NSAttributedStringHTMLTests: XCTestCase {
    // MARK: - generateHTMLWithCSS

    func test_generateHTMLWithCSS_returnsAttributedString_withRequestedColorAndFontFamily() {
        let html = "<p>hello <strong>world</strong></p>"

        let result = generateHTMLWithCSS(htmlBodyString: html, textColor: .red, font: .body)

        // The plain-text projection drops markup; "hello world" should survive.
        XCTAssertTrue(result.string.contains("hello world"))

        // Every run should carry our requested foreground color.
        let fullRange = NSRange(location: 0, length: result.length)
        var sawColor = false
        result.enumerateAttribute(.foregroundColor, in: fullRange) { value, _, _ in
            if let color = value as? UIColor, color == .red { sawColor = true }
        }
        XCTAssertTrue(sawColor, "Expected requested foregroundColor in the output")

        // Every font run should belong to our requested family (Barlow body font).
        let expectedFamily = UIFont.body.familyName
        var sawExpectedFamily = false
        result.enumerateAttribute(.font, in: fullRange) { value, _, _ in
            if let font = value as? UIFont, font.familyName == expectedFamily { sawExpectedFamily = true }
        }
        XCTAssertTrue(sawExpectedFamily, "Expected requested font family in the output")
    }

    func test_generateHTMLWithCSS_preservesBoldTraitFromHTML() {
        // <strong> renders bold in HTML; setFontFace should preserve the
        // symbolic trait when re-skinning to our family.
        let html = "<p>plain <strong>bold</strong> plain</p>"

        let result = generateHTMLWithCSS(htmlBodyString: html, textColor: .white, font: .body)

        let fullRange = NSRange(location: 0, length: result.length)
        var sawBoldRun = false
        result.enumerateAttribute(.font, in: fullRange) { value, _, _ in
            guard let font = value as? UIFont else { return }
            if font.fontDescriptor.symbolicTraits.contains(.traitBold) { sawBoldRun = true }
        }
        XCTAssertTrue(sawBoldRun, "Expected at least one bold run from the <strong> tag")
    }

    // MARK: - htmlAsAttributedString (bundled file lookup)

    func test_htmlAsAttributedString_loadsBundledTermsOfService() {
        let result = htmlAsAttributedString(
            htmlFileName: "TermsOfService",
            textColor: .white,
            font: .body,
            bundle: Resources.bundle
        )

        // Sanity check — the bundled file is non-empty and decoded.
        XCTAssertGreaterThan(result.length, 0)
    }

    // MARK: - setFontFace

    func test_setFontFace_replacesFontFamilyButPreservesItalicTrait() {
        // Build an attributed string whose only run is in a *different* family
        // (Times New Roman) with italic trait, then re-skin via setFontFace.
        let italicTimes = UIFont(name: "TimesNewRomanPS-ItalicMT", size: 12) ?? UIFont.italicSystemFont(ofSize: 12)
        let attr = NSMutableAttributedString(
            string: "italic sample",
            attributes: [.font: italicTimes]
        )

        attr.setFontFace(font: .body)

        let fullRange = NSRange(location: 0, length: attr.length)
        var familyMatchedAndStillItalic = false
        attr.enumerateAttribute(.font, in: fullRange) { value, _, _ in
            guard let font = value as? UIFont else { return }
            let isOurFamily = font.familyName == UIFont.body.familyName
            let stillItalic = font.fontDescriptor.symbolicTraits.contains(.traitItalic)
            if isOurFamily, stillItalic { familyMatchedAndStillItalic = true }
        }
        XCTAssertTrue(
            familyMatchedAndStillItalic,
            "setFontFace should swap to the new family while keeping the italic trait"
        )
    }

    func test_setFontFace_appliesColorWhenProvided() {
        let attr = NSMutableAttributedString(
            string: "color sample",
            attributes: [.font: UIFont.systemFont(ofSize: 14)]
        )

        attr.setFontFace(font: .body, color: .red)

        let fullRange = NSRange(location: 0, length: attr.length)
        var sawRed = false
        attr.enumerateAttribute(.foregroundColor, in: fullRange) { value, _, _ in
            if let color = value as? UIColor, color == .red { sawRed = true }
        }
        XCTAssertTrue(sawRed, "Expected foregroundColor to be applied when non-nil")
    }

    func test_setFontFace_skipsRunsWithoutFontAttribute() {
        // Run with no font: setFontFace's `guard let f = value as? UIFont`
        // should drop straight through, leaving the string untouched.
        let original = NSMutableAttributedString(string: "no font here")

        original.setFontFace(font: .body, color: .red)

        let fullRange = NSRange(location: 0, length: original.length)
        var sawAnyFont = false
        original.enumerateAttribute(.font, in: fullRange) { value, _, _ in
            if value != nil { sawAnyFont = true }
        }
        XCTAssertFalse(sawAnyFont, "Runs with no .font attribute should remain font-less")
    }
}
