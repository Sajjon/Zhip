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

import NanoViewControllerCore
import Resources
import UIKit

/// Loads an HTML file bundled with the app and returns it as a styled
/// `NSAttributedString`, suitable for hand-off to a `UITextView` or `UILabel`.
///
/// Used for the legal/ToS/ECC-warning copy that's authored as HTML so non-engineers
/// can edit links, lists, and headings without touching attributed-string code.
///
/// - Parameters:
///   - htmlFileName: Resource name of the `.html` file (without extension).
///   - textColor: Foreground colour applied to all text. Defaults to white to fit
///     the dark-themed app chrome.
///   - font: Base font applied to all text — see `setFontFace(font:color:)` for the
///     family/trait merging logic.
/// - Returns: An attributed string whose styling has been merged into the parsed HTML.
/// - Note: Bundling problems and parse failures crash via `incorrectImplementation`
///   because the input HTML files are static, in-bundle resources — any failure
///   indicates a programming/asset bug, not a runtime condition we should silently
///   recover from.
public func htmlAsAttributedString(
    htmlFileName: String,
    textColor: UIColor = .white,
    font: UIFont = .body,
    bundle: Bundle = Resources.bundle
) -> NSAttributedString {
    guard let path = bundle.path(forResource: htmlFileName, ofType: "html") else {
        incorrectImplementation("bad path")
    }
    do {
        let htmlBodyString = try String(contentsOfFile: path, encoding: .utf8)

        return generateHTMLWithCSS(
            htmlBodyString: htmlBodyString,
            textColor: textColor,
            font: font
        )
    } catch {
        incorrectImplementation("Failed to read contents of file, error: \(error)")
    }
}

/// Lower-level converter that wraps a raw HTML body string into a styled
/// `NSAttributedString`.
///
/// - Important: We encode using `String.Encoding.unicode` (UTF-16 in this context)
///   because `NSAttributedString.DocumentType.html` expects native-endian Unicode
///   and gets confused by some UTF-8 byte sequences (especially BOMs). This is a
///   well-known UIKit quirk.
public func generateHTMLWithCSS(
    htmlBodyString: String,
    textColor: UIColor,
    font: UIFont
) -> NSAttributedString {
    guard let htmlData = NSString(string: htmlBodyString).data(using: String.Encoding.unicode.rawValue) else {
        incorrectImplementation("Failed to convert html to data")
    }

    do {
        let attributexText = try NSMutableAttributedString(
            data: htmlData,
            options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil
        )
        // Re-skin every run with our app font and (optionally) colour while
        // preserving the symbolic traits (bold/italic) the HTML applied.
        attributexText.setFontFace(font: font, color: textColor)
        return attributexText
    } catch {
        incorrectImplementation("Failed to create attributed string")
    }
}

extension NSMutableAttributedString {
    /// Walks every `.font` run in the string and re-applies `font.familyName`
    /// while keeping the original run's symbolic traits (bold/italic/etc.).
    /// Optionally also applies `color` to the entire string.
    ///
    /// `beginEditing()`/`endEditing()` is a Foundation perf optimisation —
    /// it batches the mutation notifications so we don't pay per-attribute cost.
    func setFontFace(font: UIFont, color: UIColor? = nil) {
        beginEditing(); defer { endEditing() }

        let range = NSRange(location: 0, length: length)

        enumerateAttribute(.font, in: range) { value, range, _ in
            // Skip runs without a font, and skip the rare case where the
            // descriptor refuses the new family (e.g. font has no italic glyph).
            guard
                let f = value as? UIFont,
                let newFontDescriptor = f.fontDescriptor.withFamily(font.familyName)
                .withSymbolicTraits(f.fontDescriptor.symbolicTraits)
            else { return }

            let newFont = UIFont(descriptor: newFontDescriptor, size: font.pointSize)

            removeAttribute(.font, range: range)
            addAttribute(.font, value: newFont, range: range)

            guard let color else { return }

            removeAttribute(.foregroundColor, range: range)
            addAttribute(.foregroundColor, value: color, range: range)
        }
    }
}
