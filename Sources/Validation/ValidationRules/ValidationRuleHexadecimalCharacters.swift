// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation
import NanoViewControllerCore

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
            // Hex digits (0-9, a-f, A-F) plus the literal "0x" prefix
            // characters. Inlined here so the Validation package stays
            // free of app-specific Foundation extensions.
            let hexDigits = CharacterSet.decimalDigits
                .union(CharacterSet(charactersIn: "abcdefABCDEF"))
                .union(CharacterSet(charactersIn: "0x"))
            return hexDigits.isSuperset(of: CharacterSet(charactersIn: inputString))
        }
        self.error = error
    }

    /// Forwards to the captured nested rule.
    public func validate(input: InputType?) -> Bool {
        nestedRule.validate(input: input)
    }
}
