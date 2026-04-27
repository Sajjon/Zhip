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

import SingleLineControllerCombine
import UIKit
import XCTest
@testable import Zhip

/// Exercises `TitledValueView`'s `setValue`, `titled`, and `titleBinder` APIs
/// after configuration via `withStyles`.
final class TitledValueViewTests: XCTestCase {
    private func makeView() -> TitledValueView {
        let view = TitledValueView()
        view.withStyles()
        return view
    }

    func test_setValue_updatesValueTextView() {
        let view = makeView()

        view.setValue("42 ZIL")

        // valueTextView is fileprivate; rely on valueBinder round-tripping via
        // its underlying text. We can instead read the UITextView subview.
        let textView = view.arrangedSubviews.compactMap { $0 as? UITextView }.first
        XCTAssertEqual(textView?.text, "42 ZIL")
    }

    func test_titled_updatesTitleLabelAndReturnsSelf() {
        let view = makeView()

        let returned = view.titled("Amount")

        XCTAssertTrue(returned === view)
        let label = view.arrangedSubviews.compactMap { $0 as? UILabel }.first
        XCTAssertEqual(label?.text, "Amount")
    }

    func test_titleBinder_writesTextToLabel() {
        let view = makeView()

        view.titleBinder.on("Gas price")

        let label = view.arrangedSubviews.compactMap { $0 as? UILabel }.first
        XCTAssertEqual(label?.text, "Gas price")
    }

    func test_valueBinder_writesTextToTextView() {
        let view = makeView()

        view.valueBinder.on("0.001")

        let textView = view.arrangedSubviews.compactMap { $0 as? UITextView }.first
        XCTAssertEqual(textView?.text, "0.001")
    }
}
