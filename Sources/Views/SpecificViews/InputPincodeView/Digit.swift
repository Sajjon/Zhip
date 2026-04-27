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

/// A single decimal digit (0-9) used by `Pincode` and related input controls.
///
/// Backed by `Int` so `Digit(rawValue:)` accepts the corresponding integer literal.
enum Digit: Int, Codable, Equatable {
    case zero = 0
    case one
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
    case nine
}

extension Digit {
    /// Parses a single-character numeric string. Returns `nil` if `string` is not a
    /// decimal representation of a value in `0...9`.
    init?(string: String) {
        guard
            let int = Int(string),
            int <= 9,
            int >= 0
        else {
            return nil
        }
        self.init(rawValue: int)
    }
}

extension Digit: CustomStringConvertible {
    /// The digit's decimal representation (`"0"` through `"9"`).
    var description: String {
        String(describing: rawValue)
    }
}
