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

import Validation
import Zesame

/// Validates a gas price string in `Li`, producing a `GasPrice`.
///
/// Wraps `GasPrice(li:)` and surfaces any `Zesame.AmountError<*>` as our
/// user-facing `AmountError<Li>` so the message renders in li units.
public struct GasPriceValidator: InputValidator {
    public typealias Error = AmountError<Li>

    /// Parses `li` as a `GasPrice`; surfaces any underlying parse error.
    public func validate(input li: String) -> Validation<GasPrice, Error> {
        let gasPrice: GasPrice
        do {
            gasPrice = try GasPrice(li: li)
        } catch {
            return self.error(Error(error: error))
        }
        return .valid(gasPrice)
    }
}
