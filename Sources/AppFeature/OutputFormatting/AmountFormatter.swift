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
import NanoViewControllerCore
import Zesame

extension Zesame.Unit {
    /// User-facing name for the unit. `.li` and `.qa` use Zesame's raw name
    /// (they are jargon and not localised), while `.zil` flows through
    /// `String(localized: .Generic.zils)` so it picks up the translated form.
    var displayName: String {
        switch self {
        case .li, .qa: name
        case .zil: String(localized: .Generic.zils)
        }
    }
}

/// Formats an `ExpressibleByAmount` value for display — handles unit
/// conversion, thousands separators, decimal-digit precision, and an optional
/// trailing unit name.
///
/// Single struct rather than a free function so call sites can hold a stable
/// instance and reuse it (no per-call allocation in tight loops).
public struct AmountFormatter {
    /// Formats `amount` for display in `unit`.
    ///
    /// - Parameters:
    ///   - amount: The value to format. Any `ExpressibleByAmount` works.
    ///   - unit: The target unit (`zil`, `li`, `qa`).
    ///   - formatThousands: If `true`, inserts a thousands-separator (a space)
    ///     into the integer part — pleasant for large balances like
    ///     `1 000 000 000`.
    ///   - minFractionDigits: Forces at least this many digits after the
    ///     decimal separator (pad with trailing zeros). `nil` lets the
    ///     formatter decide.
    ///   - showUnit: If `true`, appends `" \(unit.displayName)"` to the result.
    /// - Returns: The formatted string.
    func format(
        amount: some ExpressibleByAmount,
        in unit: Zesame.Unit,
        formatThousands: Bool,
        minFractionDigits: Int? = nil,
        showUnit: Bool = false
    ) -> String {
        let amountString = amount.formatted(
            unit: unit,
            formatThousands: formatThousands,
            minFractionDigits: minFractionDigits
        )
        guard showUnit else {
            return amountString
        }

        return "\(amountString) \(unit.displayName)"
    }

    /// Because we display default tx fee of 1000 li, which is 0.001 zil, so good to show one more digit than that => 5
    static let maxNumberOfDecimalDigits = 5
}

extension ExpressibleByAmount {
    /// Formats this amount as a string in the requested unit, with optional
    /// thousands separators and minimum-fraction-digit padding.
    ///
    /// Splits the string at the locale's decimal separator and applies the
    /// `thousands` helper only to the integer part — separators inside the
    /// fractional part would look wrong (`0.123 456`).
    func formatted(
        unit targetUnit: Zesame.Unit,
        formatThousands: Bool = false,
        minFractionDigits: Int? = nil
    ) -> String {
        let string = asString(
            in: targetUnit,
            roundingIfNeeded: .down,
            roundingNumberOfDigits: AmountFormatter.maxNumberOfDecimalDigits,
            minFractionDigits: minFractionDigits
        )
        guard formatThousands else {
            return string
        }
        let decimalSeparator = Locale.current.decimalSeparatorForSure
        let components = string.components(separatedBy: decimalSeparator)
        if components.count == 2 {
            let integerPart = components[0]
            let decimalPart = components[1]
            return "\(integerPart.thousands)\(decimalSeparator)\(decimalPart)"
        } else if components.count == 1 {
            return string.thousands
        } else {
            // More than one decimal separator — not a parseable number; the
            // call site has been fed corrupt data.
            incorrectImplementation("Got components.count: \(components.count)")
        }
    }
}

extension String {
    /// Inserts a space every 3 characters from the right (`"1234567"` →
    /// `"1 234 567"`). Used by `formatted(unit:…)` to render thousands
    /// separators on the integer part.
    ///
    /// The trailing-space trim handles the corner case where the input length
    /// is an exact multiple of 3 plus one separator slot — without it, results
    /// like `"123 "` would slip through.
    var thousands: String {
        let thousandsInserted = inserting(string: " ", every: 3)
        if thousandsInserted.hasSuffix(" ") {
            return String(thousandsInserted.dropLast())
        } else {
            return thousandsInserted
        }
    }

    /// `true` iff every character in the string is a decimal digit (0-9).
    /// Used as a cheap pre-validation gate before passing strings to
    /// `Int`/`Decimal` parsers.
    func containsOnlyDecimalNumbers() -> Bool {
        guard CharacterSet(charactersIn: self).isSubset(of: CharacterSet.decimalDigits) else {
            return false
        }
        return true
    }
}
