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
import UIKit

extension PincodeTextField {
    /// The visible row of `DigitView` cells inside `PincodeTextField`.
    /// Receives no user interaction itself — the underlying invisible
    /// `UITextField` collects the keystrokes and forwards them via
    /// `setPincode(_:)`.
    final class Presentation: UIStackView {
        /// Filtered view of `arrangedSubviews` — drops the leading/trailing
        /// spacer views, leaving only the digit cells. The assert protects
        /// against accidental subview manipulation breaking the count.
        private var digitViews: [DigitView] {
            let digitViews = arrangedSubviews.compactMap { $0 as? DigitView }
            assert(digitViews.count == length)
            return digitViews
        }

        /// Number of digit cells.
        let length: Int
        /// Per-cell width.
        private let widthOfDigitView: CGFloat
        /// Whether each cell renders the entered digit or a "•".
        private let isSecureTextEntry: Bool

        /// Designated initialiser. Defaults `isSecureTextEntry` to `true`
        /// since pincode entry should be secure unless a caller explicitly
        /// opts out (e.g. for tests).
        init(length: Int, widthOfDigitView: CGFloat, isSecureTextEntry: Bool = true) {
            self.length = length
            self.widthOfDigitView = widthOfDigitView
            self.isSecureTextEntry = isSecureTextEntry
            super.init(frame: .zero)
            setup()
        }

        /// Storyboard init — unsupported, traps to enforce programmatic-only use.
        required init(coder _: NSCoder) {
            interfaceBuilderSucks
        }

        /// Re-tints every digit cell's underline (validation feedback).
        func colorUnderlineViews(with color: UIColor) {
            for digitView in digitViews {
                digitView.colorUnderlineView(with: color)
            }
        }

        /// Updates the cells to reflect the supplied digit sequence. Clears
        /// every cell first so that shorter sequences leave trailing cells
        /// blank rather than carrying over the previous state.
        func setPincode(_ digits: [Digit]) {
            for digitView in digitViews {
                digitView.updateWithNumberOrBullet(text: nil)
            }
            for (index, digit) in digits.enumerated() {
                digitViews[index].updateWithNumberOrBullet(text: String(describing: digit))
            }
        }

        /// Build the row: equal-centring horizontal stack with `length`
        /// `DigitView` cells flanked by spacer views so the cells centre
        /// regardless of the field's overall width.
        private func setup() {
            withStyle(.horizontalEqualCentering)
            [Void](repeating: (), count: length).map { DigitView(isSecureTextEntry: isSecureTextEntry) }.forEach {
                addArrangedSubview($0)
                $0.heightToSuperview()
                $0.width(widthOfDigitView)
            }

            isUserInteractionEnabled = false

            // add spacers left and right, centering the digit views
            insertArrangedSubview(.spacer, at: 0)
            addArrangedSubview(.spacer)
        }
    }
}
