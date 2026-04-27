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
import SingleLineControllerCore

/// Rule that accepts a string only if every character is a hex digit
/// (`0-9`, `a-f`, `A-F`) or part of a leading `0x` prefix.
///
/// Used by the `PrivateKey` and `Address` validators to reject obviously
/// non-hexadecimal input before the deeper crypto validation kicks in.
public struct ValidationRuleHexadecimalCharacters: ValidationRule {
    public typealias InputType = String
    /// Error to surface when the input contains a non-hex character.
    public var error: ValidationError
    /// Underlying closure-based rule that captures the character-set check.
    private let nestedRule: ValidationRuleCondition<InputType>
    /// Builds the rule with a configurable `error` so each call site can
    /// surface its own typed error (e.g. `Address.Error.notHex` vs
    /// `PrivateKey.Error.notHex`).
    public init(error: ValidationError) {
        nestedRule = ValidationRuleCondition<InputType>(error: error) {
            guard let inputString = $0 else { return false }
            return CharacterSet.hexadecimalDigitsIncluding0x.isSuperset(of: CharacterSet(charactersIn: inputString))
        }
        self.error = error
    }

    /// Forwards to the captured nested rule.
    public func validate(input: InputType?) -> Bool {
        nestedRule.validate(input: input)
    }
}

