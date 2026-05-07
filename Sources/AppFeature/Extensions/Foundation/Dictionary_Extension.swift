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

public extension Dictionary {
    /// Returns a new dictionary containing the keys of this dictionary with the
    /// non-nil results of `transform` applied to its values.
    ///
    /// Mirrors `Sequence.compactMap` for dictionary values. (Foundation now
    /// ships `Dictionary.compactMapValues(_:)` natively, so this overload is
    /// effectively a back-compat shim that may eventually be removed.)
    func compactMapValues<T>(_ transform: (Value) throws -> T?) rethrows -> [Key: T] {
        try reduce(into: [Key: T]()) { result, tuple in
            if let value = try transform(tuple.value) {
                result[tuple.key] = value
            }
        }
    }
}
