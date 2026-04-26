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
import WebKit

extension WKWebView {
    /// Programmatic-Auto-Layout-friendly initialiser: zero frame and
    /// `translatesAutoresizingMaskIntoConstraints` already disabled so the
    /// caller can immediately install constraints.
    convenience init(configuration: WKWebViewConfiguration = WKWebViewConfiguration()) {
        self.init(frame: .zero, configuration: configuration)
        translatesAutoresizingMaskIntoConstraints = false
    }

    /// Loads a bundled `.html` resource into this web view.
    /// Crashes via `incorrectImplementation` if the resource is missing or
    /// unreadable — these are static, in-bundle assets, so any failure is a
    /// programmer/asset-manifest bug rather than a runtime condition.
    func loadHtml(file: String, in bundle: Bundle = Bundle.main) {
        let htmlFile = bundle.path(forResource: file, ofType: "html")!
        guard let html = try? String(contentsOfFile: htmlFile, encoding: .utf8) else {
            incorrectImplementation("Bad HTML file, fix it please.")
        }
        loadHTMLString(html, baseURL: nil)
    }
}
