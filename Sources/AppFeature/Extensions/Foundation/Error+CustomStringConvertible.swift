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

extension Swift.Error where Self: CustomStringConvertible {
    /// Auto-derived error description that returns the case name for enum errors.
    ///
    /// Saves boilerplate for error enums that exist only to identify a failure
    /// (no associated values worth printing). For struct/class errors, or enum
    /// errors that need richer formatting, the conformer must implement
    /// `description` themselves — falling through to the trap here makes the
    /// missing implementation visible immediately.
    var description: String {
        if isEnum(type: self) {
            guard let nameOfEnumCase = nameOf(enumCase: self)
            else {
                incorrectImplementation(
                    "Fix the code that recursively extracts name of nested enums, it contains some bug."
                )
            }
            return nameOfEnumCase
        } else {
            incorrectImplementation("You need to implement `CustomStringConvertible` by adding a `description: String`")
        }
    }
}
