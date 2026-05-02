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

import UIKit

/// Abstracts loading a bundled HTML file into an `NSAttributedString`.
///
/// The default implementation uses `NSAttributedString(data:options:…)` with
/// `.documentType = .html`, which goes through WebKit and can block the main
/// thread for seconds on CI simulators. Tests register `MockHtmlLoader`, which
/// returns an empty attributed string synchronously so view setup completes
/// immediately.
public protocol HtmlLoader: AnyObject {
    /// Loads `<htmlFileName>.html` from the main bundle and returns the parsed
    /// attributed string with the given text color and font applied.
    func load(
        htmlFileName: String,
        textColor: UIColor,
        font: UIFont
    ) -> NSAttributedString
}

extension HtmlLoader {
    /// Convenience overload matching the legacy `htmlAsAttributedString`
    /// defaults (white text, body font).
    func load(htmlFileName: String) -> NSAttributedString {
        load(htmlFileName: htmlFileName, textColor: .white, font: .body)
    }
}

/// Production `HtmlLoader` backed by `htmlAsAttributedString`.
public final class DefaultHtmlLoader: HtmlLoader {
    init() {}

    public func load(
        htmlFileName: String,
        textColor: UIColor,
        font: UIFont
    ) -> NSAttributedString {
        htmlAsAttributedString(
            htmlFileName: htmlFileName,
            textColor: textColor,
            font: font
        )
    }
}
