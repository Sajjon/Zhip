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

import Foundation
import Zesame

public extension FloatingLabelTextField {
    /// Input role for a `FloatingLabelTextField`. Drives the keyboard, the
    /// allowed character set (`limitingCharacterSet`), and the validation
    /// surface used by the parent scene.
    enum TypeOfInput {
        /// Whole-number numeric pad input.
        case number
        /// Hex digits + the literal `0x` prefix characters.
        case hexadecimal
        /// Free-text input — alphanumerics only (no symbols).
        case text
        /// Password entry — no character restriction (every printable char allowed).
        case password
        /// Bech32 wallet address (with the network's prefix character).
        case bech32
        /// Either Bech32 or hex-style wallet address — used in flexible fields.
        case bech32OrHex
        /// Decimal number with locale-aware separator. Use for amount inputs.
        case decimalWithSeparator
    }
}

extension FloatingLabelTextField.TypeOfInput {
    /// Maps this input role to the `CharacterSet` used by `TextFieldDelegate`
    /// to gate keystrokes. `nil` means "no restriction" — used only for
    /// passwords, where every printable character must be allowed.
    var limitingCharacterSet: CharacterSet? {
        switch self {
        case .number: .decimalDigits
        case .decimalWithSeparator: .decimalWithSeparator
        case .hexadecimal: .hexadecimalDigitsIncluding0x
        case .bech32: .bech32IncludingPrefix
        case .password: nil
        case .text: .alphanumerics
        case .bech32OrHex: .bech32OrHexIncludingPrefix
        }
    }
}
