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
import Validation
import XCTest

/// Covers UIView extensions: `shake(...)` animation and the publisher binders
/// not already exercised elsewhere.
@MainActor
final class UIViewExtensionsTests: XCTestCase {
    func test_shake_invokesCompletionCallback() {
        let view = UIView()
        let expectation = expectation(description: "done")

        view.shake(duration: 0.01, withTranslation: 1) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)
    }

    func test_shake_withoutCompletion_doesNotCrash() {
        let view = UIView()

        view.shake(duration: 0.01, withTranslation: 1)
    }

    // MARK: - UIView.Border

    func test_border_errorPreset_appliesErrorColor() {
        let border = UIView.Border.error

        XCTAssertEqual(border.color, AnyValidation.Color.error.cgColor)
    }

    func test_border_fromValidation_validWithoutRemark_usesValidWithoutRemarkColor() {
        let border = UIView.Border.fromValidation(.valid(withRemark: nil))

        XCTAssertEqual(border.color, AnyValidation.Color.validWithoutRemark.cgColor)
    }

    func test_border_fromValidation_validWithRemark_usesValidWithRemarkColor() {
        let border = UIView.Border.fromValidation(.valid(withRemark: "looks good"))

        XCTAssertEqual(border.color, AnyValidation.Color.validWithRemark.cgColor)
    }

    // MARK: - UILayoutPriority literal initializers

    func test_layoutPriority_floatLiteral_initializes() {
        let priority: UILayoutPriority = 123.5

        XCTAssertEqual(priority.rawValue, 123.5)
    }

    func test_layoutPriority_integerLiteral_initializes() {
        let priority: UILayoutPriority = 700

        XCTAssertEqual(priority.rawValue, 700)
    }

    // MARK: - UIImageView+Styling

    func test_imageView_setOptional_appliesValueWhenNotNil() {
        let imageView = UIImageView()
        let image = UIImage()

        imageView.setOptional(\.image, ifNotNil: image)

        XCTAssertTrue(imageView.image === image)
    }

    func test_imageView_setOptional_doesNothingWhenNil() {
        let imageView = UIImageView()
        imageView.image = UIImage()
        let before = imageView.image

        imageView.setOptional(\.image, ifNotNil: nil)

        XCTAssertTrue(imageView.image === before)
    }

    func test_imageViewStyle_backgroundColorBuilder_setsBackgroundColor() {
        let style = UIImageView.Style().backgroundColor(.red)

        XCTAssertEqual(style.backgroundColor, .red)
    }
}
