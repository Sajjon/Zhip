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

import Foundation

/// Reflects `enumToMirror` and returns the name of the active case
/// (e.g. `.foo(42)` → `"foo"`), falling back to the case's string value if
/// no label is present, and `String(describing:)` for cases without payloads.
///
/// Used by analytics / logging code that wants to emit a stable identifier for
/// an enum case without enumerating every variant by hand.
public func nameOf(enumCase enumToMirror: Any) -> String? {
    guard isEnum(type: enumToMirror) else { return nil }
    let mirror = Mirror(reflecting: enumToMirror)
    if let enumCase = mirror.children.first {
        return enumCase.label ?? (enumCase.value as? String)
    } else {
        return String(describing: enumToMirror)
    }
}

/// `true` iff `type` is an enum value (i.e. its `Mirror.displayStyle` is `.enum`).
public func isEnum(type: Any) -> Bool {
    let mirror = Mirror(reflecting: type)
    guard
        let displayStyle = mirror.displayStyle,
        displayStyle == .enum
    else { return false }
    return true
}
