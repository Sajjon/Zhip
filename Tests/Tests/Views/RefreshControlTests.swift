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
final class RefreshControlTests: XCTestCase {
    func test_init_appliesProgrammaticDefaults() {
        let sut = RefreshControl()

        XCTAssertEqual(sut.backgroundColor, .clear)
        XCTAssertEqual(sut.contentMode, .scaleToFill)
        XCTAssertTrue(sut.autoresizingMask.contains(.flexibleWidth))
        XCTAssertTrue(sut.autoresizingMask.contains(.flexibleHeight))
    }

    func test_init_seatsStackViewInsideControl() {
        let sut = RefreshControl()

        // The internal stack view (spinner + label) is added as a subview.
        // Beyond UIKit's default subviews (the system spinner), there should be
        // at least our custom UIStackView.
        XCTAssertTrue(sut.subviews.contains(where: { $0 is UIStackView }))
    }

    func test_didMoveToSuperview_zerosFirstSubviewAlpha() {
        // RefreshControl's didMoveToSuperview hack sets the system spinner's
        // alpha to zero so it doesn't render alongside our custom SpinnerView.
        // UIRefreshControl needs a UIScrollView superview at runtime, otherwise
        // UIKit asserts on the system spinner's internal scroll-view lookup.
        let sut = RefreshControl()
        let scroll = UIScrollView()
        scroll.refreshControl = sut

        // Forces didMoveToSuperview to fire (refreshControl assignment installs
        // the control as a subview of the scroll view).
        XCTAssertEqual(sut.subviews.first?.alpha, 0)
    }

    func test_didMoveToSuperview_isNoOpWhenSuperviewIsNil() {
        let sut = RefreshControl()
        let initialFirstAlpha = sut.subviews.first?.alpha ?? 1

        // No superview installed → the early return guard fires.
        sut.didMoveToSuperview()

        XCTAssertEqual(sut.subviews.first?.alpha, initialFirstAlpha)
    }

    func test_setTitle_updatesLabelText() {
        let sut = RefreshControl()
        // Find the label in the stack view (spinner is first, label is second).
        guard let stack = sut.subviews.first(where: { $0 is UIStackView }) as? UIStackView,
              let label = stack.arrangedSubviews.compactMap({ $0 as? UILabel }).first
        else {
            XCTFail("Expected RefreshControl to host a UIStackView containing a UILabel")
            return
        }

        sut.setTitle("Refreshing...")

        XCTAssertEqual(label.text, "Refreshing...")
    }

    func test_init_seedsLabelWithLocalizedPullToRefreshTitle() {
        let sut = RefreshControl()
        guard let stack = sut.subviews.first(where: { $0 is UIStackView }) as? UIStackView,
              let label = stack.arrangedSubviews.compactMap({ $0 as? UILabel }).first
        else {
            XCTFail("Expected RefreshControl to host a UIStackView containing a UILabel")
            return
        }

        // Whatever the localised title resolves to — confirm it's non-empty so
        // we know the init path actually populated the label.
        XCTAssertFalse(label.text?.isEmpty ?? true)
    }
}
