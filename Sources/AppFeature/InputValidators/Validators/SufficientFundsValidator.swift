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

import Validation
import Zesame

/// Cross-field validator for the Send screen: confirms the user has enough
/// balance to cover `amount + gasLimit*gasPrice` before allowing the
/// transaction to be submitted.
///
/// All four inputs are optional because each is validated by its own
/// per-field validator first; until they all resolve to non-nil values, this
/// validator returns `.invalid(.empty)` (neutral grey state).
public struct SufficientFundsValidator: InputValidator {
    /// Possible failures.
    public enum Error: Swift.Error {
        /// Balance is less than `amount + estimated fee`.
        case insufficientFunds
        /// Underlying arithmetic threw a typed amount error (e.g. overflow).
        case amountError(AmountError<Amount>)
    }

    // swiftlint:disable large_tuple

    /// Computes the estimated total cost (amount + gas*price) and compares against the balance.
    /// Returns `.valid(amount)` when the user can afford the transaction, `.invalid` otherwise.
    public func validate(input: (
        amount: Amount?,
        gasLimit: GasLimit?,
        gasPrice: GasPrice?,
        balance: Amount?
    ))
        -> Validation<Amount, Error>
    {
        guard let amount = input.amount, let gasLimit = input.gasLimit, let gasPrice = input.gasPrice,
              let balance = input.balance
        else {
            return .invalid(.empty)
        }

        do {
            let totalCost = try Payment.estimatedTotalCostOfTransaction(
                amount: amount,
                gasPrice: gasPrice,
                gasLimit: gasLimit
            )
            guard totalCost <= balance else {
                return self.error(Error.insufficientFunds)
            }
        } catch let error as AmountError<Amount> {
            return self.error(Error.amountError(error))
        } catch let otherError {
            // Catch-all path — wrap arbitrary errors in our typed AmountError
            // via the reflective initializer rather than dropping them silently.
            let zilAmountError: AmountError<Amount> = .init(error: otherError)
            return self.error(Error.amountError(zilAmountError))
        }

        return .valid(amount)
    }

    // swiftlint:enable large_tuple
}

extension SufficientFundsValidator.Error: InputError {
    /// Localized error string — `.insufficientFunds` uses our balance-specific
    /// copy, `.amountError` defers to the wrapped error's own message.
    public var errorMessage: String {
        switch self {
        case .insufficientFunds: String(localized: .Errors.amountExceedingBalance)
        case let .amountError(amountError): amountError.errorMessage
        }
    }
}
