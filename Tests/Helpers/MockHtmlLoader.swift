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
@testable import AppFeature

/// In-test `HtmlLoader` that NEVER invokes the WebKit-backed
/// `NSAttributedString(data:options:…)` parser. Returns an empty attributed
/// string synchronously so UIKit view setup completes immediately — the real
/// parser blocks the main thread for seconds on CI simulators, which with
/// `UIView.setAnimationsEnabled(false)` (synchronous modal presentation) would
/// time out `drainRunLoop()`.
final class MockHtmlLoader: HtmlLoader {
    /// File names passed to `load(…)`, in call order.
    private(set) var loadInvocations: [String] = []

    init() {}

    func load(
        htmlFileName: String,
        textColor _: UIColor,
        font _: UIFont
    ) -> NSAttributedString {
        loadInvocations.append(htmlFileName)
        return NSAttributedString()
    }
}
