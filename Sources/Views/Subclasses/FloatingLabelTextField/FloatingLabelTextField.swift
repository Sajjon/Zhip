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
import SkyFloatingLabelTextField
import UIKit
import Validation

/// Diameter (in points) of the small validation status circle on the leading edge.
private let circeViewSize: CGFloat = 16
/// Total leading-padding width = circle + 12pt gap to the text.
private let leftPaddingViewWidth: CGFloat = circeViewSize + 12
/// Distance from the circle's bottom edge to the field's bottom — aligns the
/// circle with the bottom-line indicator that `SkyFloatingLabelTextField` draws.
private let distanceBetweenCircleAndBottom: CGFloat = 10

/// Project's standard input field. Subclass of `SkyFloatingLabelTextField`
/// (a third-party "floating label" text field) augmented with:
///   - a coloured validation status circle on the leading edge,
///   - a `TextFieldDelegate` that limits keystrokes by `TypeOfInput`,
///   - the `withStyle(_:customize:)` API matching the rest of the app's styling.
final class FloatingLabelTextField: SkyFloatingLabelTextField {
    /// Standard width of the right accessory view (clear button, eye toggle, …).
    static let rightViewWidth: CGFloat = 45
    /// Standard height of the field. Drives several layout calculations
    /// (text/title halves, accessory positioning).
    static let textFieldHeight: CGFloat = 64

    /// Container that holds the validation circle on the leading edge.
    private lazy var leftPaddingView = UIView()
    /// Coloured status circle. `internal` so the validation extension can
    /// re-tint it.
    lazy var validationCircleView = UIView()
    /// Per-field delegate that limits keystrokes by `TypeOfInput`. Wiring is
    /// done in `withStyle(_:customize:)`.
    private lazy var textFieldDelegate = TextFieldDelegate()

    // MARK: - Overridden methods

    /// Offset X so that label does not collide with leftView
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        let superRect = super.placeholderRect(forBounds: bounds)
        return superRect.insetBy(dx: leftPaddingView.frame.width, dy: 0)
    }

    /// Half the field's overall height — yields a text area sized so the
    /// floating-label title fits in the upper half and the input in the lower.
    override func textHeight() -> CGFloat {
        FloatingLabelTextField.textFieldHeight / 2
    }

    /// Half the field's overall height — see `textHeight()`.
    override func titleHeight() -> CGFloat {
        FloatingLabelTextField.textFieldHeight / 2
    }

    /// Re-apply font-resizing whenever the error message changes — see
    /// `updateFontResizing()` for the resizing logic.
    override var errorMessage: String? {
        didSet { updateFontResizing() }
    }

    /// Pin the leading view to the precomputed left-padding rect so the
    /// status circle sits in the gutter rather than overlapping the text.
    override func leftViewRect(forBounds _: CGRect) -> CGRect {
        leftPaddingView.frame
    }

    /// Force the right accessory view to fill the full field height (so a
    /// clear button is centred vertically, not aligned to the text baseline).
    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        var rightViewRect = super.rightViewRect(forBounds: bounds)
        rightViewRect.origin.y = 0
        var size = rightViewRect.size
        size.height = FloatingLabelTextField.textFieldHeight
        size.width = FloatingLabelTextField.rightViewWidth
        rightViewRect.size = size
        return rightViewRect
    }

    /// Allowing for slightly smaller font size for error messages that otherwise would not fit.
    /// Shrinking is only performed on the label when showing error messages.
    private func updateFontResizing() {
        titleLabel.adjustsFontSizeToFitWidth = errorMessage != nil
    }
}

// MARK: TextField + Styling

extension FloatingLabelTextField {
    /// Apply `style` (optionally customised) and install the `TextFieldDelegate`.
    /// Same call shape as the other `withStyle(_:customize:)` overloads in the
    /// styling system. Returns `self` for chaining.
    @discardableResult
    func withStyle(
        _ style: FloatingLabelTextField.Style,
        customize: ((FloatingLabelTextField.Style) -> FloatingLabelTextField.Style)? = nil
    ) -> FloatingLabelTextField {
        defer { delegate = textFieldDelegate }
        apply(style: customize?(style) ?? style)
        setup()
        return self
    }

    /// Switches the input policy at runtime. Used when a single field changes
    /// roles (e.g. amount field switching between integer and decimal).
    func updateTypeOfInput(_ typeOfInput: TypeOfInput) {
        textFieldDelegate.setTypeOfInput(typeOfInput)
    }
}

extension FloatingLabelTextField {
    /// Reactive sink — bind a publisher of `AnyValidation` to drive the
    /// field's validation appearance (line colour, error message, status circle).
    var validationBinder: Binder<AnyValidation> {
        Binder<AnyValidation>(self) { (textField: FloatingLabelTextField, validation: AnyValidation) in
            textField.applyValidation(validation)
        }
    }
}

// MARK: - Private

private extension FloatingLabelTextField {
    /// One-time configuration of the field's structural visuals: colours,
    /// title-label sizing, and the leading status circle.
    /// `setupValidationCircleView()` is `defer`red so it runs after the rest
    /// of the configuration — its position depends on the final field size.
    func setup() {
        defer {
            // calculations of the position of the circle view might be dependent on other settings, thus do it last
            setupValidationCircleView()
        }
        translatesAutoresizingMaskIntoConstraints = false
        lineErrorColor = AnyValidation.Color.error
        lineColor = AnyValidation.Color.empty
        textErrorColor = .white
        titleLabel.numberOfLines = 2
        titleLabel.minimumScaleFactor = 0.8
        updateColorsWithValidation(.empty)

        // prevent capitalization of strings
        titleFormatter = { $0 }
    }

    /// Builds the validation circle, rounds it to a perfect circle, and seats
    /// it inside the leading padding view. `leftView`/`leftViewMode` install
    /// the padding view as the field's leading accessory.
    func setupValidationCircleView() {
        validationCircleView.translatesAutoresizingMaskIntoConstraints = false
        leftPaddingView.addSubview(validationCircleView)
        validationCircleView.size(CGSize(width: circeViewSize, height: circeViewSize))
        validationCircleView.bottomToSuperview(offset: -distanceBetweenCircleAndBottom)
        validationCircleView.leftToSuperview()
        UIView.Rounding.static(circeViewSize / 2).apply(to: validationCircleView)

        leftView = leftPaddingView
        leftViewMode = .always
        leftPaddingView.frame = CGRect(
            x: 0,
            y: 0,
            width: leftPaddingViewWidth,
            height: FloatingLabelTextField.textFieldHeight
        )
    }
}
