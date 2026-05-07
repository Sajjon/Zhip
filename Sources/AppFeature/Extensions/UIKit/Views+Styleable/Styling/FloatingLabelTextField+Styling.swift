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

import UIKit

// Same Style/Apply/Customizing/Presets shape as `UILabel+Styling.swift` —
// see that file for the canonical doc walkthrough.
//
// Unique here is `typeOfInput` — a non-optional input policy (text, password,
// hexadecimal, etc.) that drives both keyboard and validation, since a
// floating-label field always belongs to one specific input role.

public extension FloatingLabelTextField {
    /// Description of a `FloatingLabelTextField`'s appearance + input policy.
    /// Unlike the other Style structs, `typeOfInput` is required (non-optional)
    /// because every field has *some* input role.
    struct Style {
        /// Input role — drives keyboard, allowed character set, validation hooks.
        public var typeOfInput: TypeOfInput
        /// Placeholder copy (also displayed in the floating label area).
        public var placeholder: String?
        public let textColor: UIColor?
        public let font: UIFont?
        public let placeholderFont: UIFont?
        public let isSecureTextEntry: Bool?
        public let keyboardType: UIKeyboardType?
        public let backgroundColor: UIColor?

        /// Memberwise initialiser — only `typeOfInput` is required, the rest
        /// fall back to project-wide defaults in `apply(style:)`.
        public init(
            typeOfInput: TypeOfInput,
            placeholder: String? = nil,
            font: UIFont? = nil,
            placeholderFont: UIFont? = nil,
            textColor: UIColor? = nil,
            backgroundColor: UIColor? = nil,
            isSecureTextEntry: Bool? = nil,
            keyboardType: UIKeyboardType? = nil
        ) {
            self.typeOfInput = typeOfInput
            self.placeholder = placeholder
            self.font = font
            self.placeholderFont = placeholderFont
            self.textColor = textColor
            self.isSecureTextEntry = isSecureTextEntry
            self.keyboardType = keyboardType
            self.backgroundColor = backgroundColor
        }
    }
}

// MARK: - Apply Syyle

public extension FloatingLabelTextField {
    /// Writes `style` to this field, substituting project-wide defaults for any
    /// nil attribute and routing `typeOfInput` through `updateTypeOfInput`
    /// (which configures keyboard/auto-correct/text-content-type in one step).
    func apply(style: Style) {
        updateTypeOfInput(style.typeOfInput)
        textColor = style.textColor ?? .defaultText
        placeholder = style.placeholder
        placeholderFont = style.placeholderFont ?? UIFont.Field.floatingPlaceholder
        font = style.font ?? UIFont.Field.textAndPlaceholder
        isSecureTextEntry = style.isSecureTextEntry ?? false
        if let keyboardType = style.keyboardType {
            self.keyboardType = keyboardType
        }
        backgroundColor = style.backgroundColor ?? .clear
    }
}

// MARK: - Style + Customizing

public extension FloatingLabelTextField.Style {
    /// Returns a copy with `placeholder` replaced — the most common per-field
    /// override applied via the `withStyle(_:customize:)` `customize` closure.
    @discardableResult
    func placeholder(_ placeholder: String?) -> FloatingLabelTextField.Style {
        var style = self
        style.placeholder = placeholder
        return style
    }
}

// MARK: - Style Presets

public extension FloatingLabelTextField.Style {
    /// Plain free-text input — no special validation, default keyboard.
    static var text: FloatingLabelTextField.Style {
        FloatingLabelTextField.Style(
            typeOfInput: .text
        )
    }

    /// Wallet address input — accepts either Bech32 (`zil1…`) or hex addresses.
    /// The character-set restriction is enforced by `typeOfInput`.
    static var addressBech32OrHex: FloatingLabelTextField.Style {
        FloatingLabelTextField.Style(
            typeOfInput: .bech32OrHex
        )
    }

    /// Encryption-password input — secure entry on by default so the OS
    /// shouldn't suggest auto-fill or expose the contents.
    static var password: FloatingLabelTextField.Style {
        FloatingLabelTextField.Style(
            typeOfInput: .password,
            isSecureTextEntry: true
        )
    }

    /// Private key input — secure entry plus hex-only character restriction.
    /// Highest sensitivity input in the app.
    static var privateKey: FloatingLabelTextField.Style {
        FloatingLabelTextField.Style(
            typeOfInput: .hexadecimal,
            isSecureTextEntry: true
        )
    }

    /// Whole-number input with the system numeric keyboard.
    static var number: FloatingLabelTextField.Style {
        FloatingLabelTextField.Style(
            typeOfInput: .number,
            keyboardType: .numberPad
        )
    }

    /// Decimal-amount input with locale-aware separator handling and the
    /// system decimal keypad.
    static var decimal: FloatingLabelTextField.Style {
        FloatingLabelTextField.Style(
            typeOfInput: .decimalWithSeparator,
            keyboardType: .decimalPad
        )
    }
}
