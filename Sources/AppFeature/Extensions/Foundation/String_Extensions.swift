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

import UIKit

extension String {
    /// Where to start chunking when inserting a separator every N characters.
    /// Currently only `.end` is implemented (right-to-left chunking, used for
    /// digit grouping in numeric formatting).
    enum CharacterInsertionPlace {
        /// Start from the *right* edge — useful for "1,000,000"-style grouping
        /// where the trailing chunk may be shorter than the chunk size.
        case end
    }

    /// Returns a copy of this string with `string` inserted every `interval`
    /// characters, chunked from the right (`.end`). E.g. `"1234567".inserting(string: ",", every: 3)`
    /// yields `"1,234,567"`.
    func inserting(string: String, every interval: Int) -> String {
        String.inserting(string: string, every: interval, in: self)
    }

    /// Static counterpart of the instance method — same semantics, exposed so
    /// call sites can chunk a string they don't own. Returns the input unchanged
    /// when shorter than `interval`.
    static func inserting(
        string character: String,
        every interval: Int,
        in string: String,
        at insertionPlace: CharacterInsertionPlace = .end
    ) -> String {
        guard string.count > interval else { return string }
        var string = string
        var new = ""

        switch insertionPlace {
        case .end:
            // Iterate right-to-left, peeling `interval` chars at a time off the
            // tail of `string` and prepending them (with a separator) onto `new`.
            // The leading remainder (shorter than `interval`) is glued on after.
            while let piece = string.droppingLast(interval) {
                let toAdd: String = string.isEmpty ? "" : character
                new = "\(toAdd)\(piece)\(new)"
            }
            if !string.isEmpty {
                new = "\(string)\(new)"
            }
        }

        return new
    }

    /// Mutating tail-pop: removes the last `toDrop` characters from this string
    /// and returns them as a new string. Returns `nil` (and leaves the receiver
    /// unchanged) if the string is shorter than `toDrop`.
    mutating func droppingLast(_ toDrop: Int) -> String? {
        guard toDrop <= count else { return nil }
        let string = String(suffix(toDrop))
        removeLast(toDrop)
        return string
    }

    /// Measures this string when rendered in `font` using the platform's
    /// attributed-string sizing. Bridges via `NSString` because `String.size(...)`
    /// requires importing UIKit categories.
    func sizeUsingFont(_ font: UIFont) -> CGSize {
        (self as NSString).size(withAttributes: [.font: font])
    }

    /// Convenience that drops the height — useful when laying out single-line
    /// labels by intrinsic width.
    func widthUsingFont(_ font: UIFont) -> CGFloat {
        sizeUsingFont(font).width
    }
}
