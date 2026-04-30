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

import SingleLineControllerCore
import Zesame
import Validation

/// Validates an amount string in a specific Zilliqa `Unit` (Zil/Li/Qa).
///
/// Generic over the target `Amount` type so it works for `Amount`, `Zil`,
/// `Li`, `Qa`, and `GasPrice` alike — each call site picks the strongest
/// type the use case will eventually receive.
public struct AmountValidator<Amount: ExpressibleByAmount>: InputValidator {
    public typealias Error = AmountError<Amount>

    /// Delegates to `AmountFromText.init(string:unit:)` and translates any
    /// `Zesame.AmountError<*>` into our user-facing `AmountError`.
    public func validate(
        input: (amountString: String, unit: Zesame.Unit)
    ) -> Validation<AmountFromText<Amount>, Error> {
        let (amountString, unit) = input
        do {
            return try .valid(AmountFromText(string: amountString, unit: unit))
        } catch {
            return self.error(Error(error: error))
        }
    }
}

/// User-facing amount error generic over the unit the message should be rendered in.
///
/// `ConvertTo.unit` controls how `tooLarge`/`tooSmall` numbers are formatted in
/// the message — the parser may have failed in `Qa` but if the field shows `Zil`,
/// we want to show "max 1.0 ZIL" not "max 1_000_000_000_000 QA".
public enum AmountError<ConvertTo: ExpressibleByAmount>: Swift.Error, InputError {
    /// Amount exceeds the per-unit upper bound.
    case tooLarge(max: String, unit: Unit)
    /// Amount falls below the per-unit lower bound.
    case tooSmall(min: String, unit: Unit, showUnit: Bool = true)
    /// String didn't parse as a number at all.
    case nonNumericString
    /// Catch-all wrapper for unexpected errors.
    case other(Swift.Error)

    /// Reflective initializer that tries each typed `Zesame.AmountError<*>`
    /// in turn and falls back to `.other` if none match.
    init(error: Swift.Error) {
        if let zilError = error as? Zesame.AmountError<Zil> {
            self.init(zesameError: zilError)
        } else if let liError = error as? Zesame.AmountError<Li> {
            self.init(zesameError: liError)
        } else if let qaError = error as? Zesame.AmountError<Qa> {
            self.init(zesameError: qaError)
        } else if let gasPriceError = error as? Zesame.AmountError<GasPrice> {
            self.init(zesameError: gasPriceError)
        } else if let zilAmountError = error as? Zesame.AmountError<Amount> {
            self.init(zesameError: zilAmountError)
        } else {
            self = .other(error)
        }
    }

    /// Translation for bounded amount types (`Zil`, `Li`, `Qa`, `GasPrice`).
    /// The bound values are converted to `ConvertTo.unit` so the message
    /// renders in whatever unit the field is currently displaying.
    init(zesameError: Zesame.AmountError<some ExpressibleByAmount & Upperbound & Lowerbound>) {
        switch zesameError {
        case .nonNumericString, .endsWithDecimalSeparator, .moreThanOneDecimalSeparator, .tooManyDecimalPlaces,
             .containsNonDecimalStringCharacter: self = .nonNumericString
        case let .tooLarge(max):
            let convertedMax = max.asString(in: ConvertTo.unit)
            self = .tooLarge(max: convertedMax, unit: ConvertTo.unit)
        case let .tooSmall(min):
            let convertedMin = min.asString(in: ConvertTo.unit)
            self = .tooSmall(min: convertedMin, unit: ConvertTo.unit)
        }
    }

    /// Translation for unbounded amount types (`Amount`). `tooLarge`/`tooSmall`
    /// shouldn't reach this overload; if they do it indicates a logic bug.
    init(zesameError: Zesame.AmountError<some ExpressibleByAmount & Unbound>) {
        switch zesameError {
        case .nonNumericString, .endsWithDecimalSeparator, .moreThanOneDecimalSeparator, .tooManyDecimalPlaces,
             .containsNonDecimalStringCharacter: self = .nonNumericString
        case .tooLarge,
             .tooSmall: incorrectImplementation("Unbound amounts should not throw `tooLarge` or `tooSmall` errors")
        }
    }

    /// Localized error string rendered on the Send/Gas screens.
    public var errorMessage: String {
        switch self {
        case let .tooLarge(
            max,
            unit
        ): String(localized: .Errors.amountTooLarge(maximum: "\(max.thousands) \(unit.name)"))
        case let .tooSmall(min, unit, shouldShowUnit):
            if shouldShowUnit {
                String(localized: .Errors.amountTooSmall(minimum: "\(min.thousands) \(unit.name)"))
            } else {
                String(localized: .Errors.amountTooSmall(minimum: "\(min.thousands)"))
            }
        case .nonNumericString: String(localized: .Errors.amountNonNumericString)
        case .other: String(localized: .Errors.amountNonNumericString) // TODO: which error message to display?
        }
    }
}
