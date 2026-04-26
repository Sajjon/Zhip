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

/// Recursively peels associated values off `parent` (assumed to be an enum case)
/// until it finds a value of type `Nested`, or runs out of `recursiveTriesLeft`.
///
/// Used to extract a typed payload from a deeply-nested coordinator step
/// without forcing every intermediate enum to expose a typed accessor.
///
/// - Parameters:
///   - wantedType: Type witness for `Nested` — needed at the call site so the
///     compiler can infer the generic; not actually used at runtime.
///   - parent: The enum case being mirrored.
///   - recursiveTriesLeft: Recursion budget. Decremented on every step that
///     fails to match `Nested`. Returns `nil` when exhausted.
func findNestedEnumOfType<Nested>(_ wantedType: Nested.Type, in parent: Any, recursiveTriesLeft: Int) -> Nested? {
    guard recursiveTriesLeft >= 0 else { return nil }

    guard
        case let mirror = Mirror(reflecting: parent),
        let displayStyle = mirror.displayStyle,
        displayStyle == .enum,
        let child = mirror.children.first
    else { return nil }

    guard let needle = child.value as? Nested
    else { return findNestedEnumOfType(wantedType, in: parent, recursiveTriesLeft: recursiveTriesLeft - 1) }

    return needle
}
