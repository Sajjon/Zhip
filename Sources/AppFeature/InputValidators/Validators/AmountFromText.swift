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

/// Either a fully-parsed `Amount` (success) or the raw string the user is in
/// the middle of typing (mid-edit, e.g. "12.").
///
/// Storing the raw string for the "user just typed a decimal separator" case
/// lets the view continue showing what they typed without rolling back the
/// caret or losing the trailing separator.
public enum AmountFromText<Amount: ExpressibleByAmount> {
    /// Successful parse with the resolved unit.
    case amount(Amount, in: Zesame.Unit)
    /// In-progress text that's not yet a valid number (e.g. "12.").
    case string(String)
}

extension AmountFromText {
    /// The parsed `Amount` if available, else `nil`.
    var amount: Amount? {
        guard case let .amount(amount, _) = self else { return nil }
        return amount
    }

    /// The raw in-progress string if available, else `nil`.
    var string: String? {
        guard case let .string(text) = self else { return nil }
        return text
    }
}

extension AmountFromText {
    /// Parses `amountString` in `unit`, normalizing the decimal separator to
    /// the current locale (so "1,5" entered on a Swedish keyboard works just
    /// like "1.5" entered on a US keyboard).
    ///
    /// Special-cases `endsWithDecimalSeparator` to keep the raw string visible
    /// rather than blowing up while the user is mid-typing.
    init(string amountString: String, unit: Zesame.Unit) throws {
        let correctSeparator = Locale.current.decimalSeparatorForSure
        let wrongSeparator = correctSeparator == "." ? "," : "."

        let incorrectDecimalSeparatorRemoved = amountString.replacingOccurrences(
            of: wrongSeparator,
            with: correctSeparator
        )
        do {
            let amount: Amount = switch unit {
            case .zil:
                try Amount(zil: Zil(trimming: incorrectDecimalSeparatorRemoved))
            case .li:
                try Amount(li: Li(trimming: incorrectDecimalSeparatorRemoved))
            case .qa:
                try Amount(qa: Qa(trimming: incorrectDecimalSeparatorRemoved))
            }
            self = .amount(amount, in: unit)
        } catch {
            // Special-case: the user just typed "1." — not a valid number yet,
            // but we want to preserve their text so the caret stays put.
            if let zilAmountError = error as? Zesame.AmountError<Amount>, zilAmountError == .endsWithDecimalSeparator {
                self = .string(incorrectDecimalSeparatorRemoved)
            } else if let zilError = error as? Zesame.AmountError<Zil>, zilError == .endsWithDecimalSeparator {
                self = .string(incorrectDecimalSeparatorRemoved)
            } else {
                throw error
            }
        }
    }
}
