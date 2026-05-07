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

/// `UITextFieldDelegate` that gates input by character set and max length.
///
/// Used by `FloatingLabelTextField` to enforce per-input-type rules without
/// scenes having to install their own delegates — pick a `TypeOfInput`
/// (text/hex/decimal/...) and the matching character set is derived for you.
///
/// The class is deliberately stateless beyond config (no per-call mutation)
/// so a single instance can serve any number of fields.
public final class TextFieldDelegate: NSObject {
    /// Maximum allowed text length, or `nil` for unlimited.
    private let maxLength: Int?
    /// Character set the user is allowed to type. `nil` ⇒ no restriction.
    /// Mutable via `setTypeOfInput(_:)` so a field can switch input modes
    /// at runtime (e.g. when the user changes a "type" segmented control).
    private var limitingCharacterSet: CharacterSet?

    /// Designated initialiser — pass a precomputed `CharacterSet`. Use the
    /// `init(type:maxLength:)` convenience overload below for the common
    /// "I have a TypeOfInput value" case.
    init(limitingCharacterSet: CharacterSet?, maxLength: Int? = nil) {
        self.limitingCharacterSet = limitingCharacterSet
        self.maxLength = maxLength
    }
}

extension TextFieldDelegate {
    /// Convenience init that derives the character set from a `TypeOfInput`.
    /// Most call sites use this — it keeps the input-type ↔ allowed-chars
    /// mapping in `TypeOfInput` rather than scattered across delegate setups.
    convenience init(type: FloatingLabelTextField.TypeOfInput = .text, maxLength: Int? = nil) {
        self.init(limitingCharacterSet: type.limitingCharacterSet, maxLength: maxLength)
    }

    /// Live-swap the input policy. Used when a single field changes role
    /// (e.g. amount field switching between integer and decimal mode).
    func setTypeOfInput(_ typeOfInput: FloatingLabelTextField.TypeOfInput) {
        limitingCharacterSet = typeOfInput.limitingCharacterSet
    }
}

extension TextFieldDelegate: UITextFieldDelegate {
    /// `UITextFieldDelegate` hook called for every character insertion or paste.
    /// Returns `false` to reject the change; `true` to accept it.
    ///
    /// Three checks in order:
    ///   1. Backspace always passes (so the user can always recover from a
    ///      previously-pasted bad value).
    ///   2. If the new characters fall outside `limitingCharacterSet`, reject
    ///      — covers both per-keystroke typing and pasted strings.
    ///   3. If accepting would exceed `maxLength`, reject.
    ///
    /// The trailing `defer` block normalises the locale-specific decimal
    /// separator: when the locale uses ',' but the user types '.' (or vice
    /// versa), we substitute the right one in-place. Done in `defer` so it
    /// runs after UIKit has applied the (accepted) edit.
    public func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        defer {
            let correctSeparator = Locale.current.decimalSeparatorForSure
            let wrongSeparator = correctSeparator == "." ? "," : "."
            textField.text = textField.text?.replacingOccurrences(of: wrongSeparator, with: correctSeparator)
        }

        // Always allow erasing of digit
        if string.isBackspace { return true }

        if let limitingCharacterSet, !CharacterSet(charactersIn: string).isSubset(of: limitingCharacterSet) {
            // Dont allow pasting of non allowed chacracters
            return false
        }

        guard let maxLength else {
            return true
        }
        let newLength = (textField.text?.count ?? 0) + string.count - range.length
        // Dont allow pasting of strings longer than max length
        return newLength <= maxLength
    }
}
