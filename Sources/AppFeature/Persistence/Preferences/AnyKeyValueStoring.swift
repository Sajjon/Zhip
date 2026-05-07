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

/// A simple non thread safe, non async, key value store without associatedtypes
///
/// This is the *type-erased base* of the persistence layer. The strongly-typed
/// `KeyValueStoring` protocol below it adds an `associatedtype Key: KeyConvertible`
/// (so callers can pass enum cases instead of raw strings), but at the very bottom
/// every concrete backend (UserDefaults, KeychainSwift) speaks `String`-keyed
/// `Any?` values — exactly what this protocol exposes.
public protocol AnyKeyValueStoring {
    /// Persists `value` under `key`. The receiver chooses the storage strategy
    /// (UserDefaults plist serialization, Keychain item, in-memory dict, etc.).
    func save(value: Any, for key: String)

    /// Retrieves whatever was previously stored under `key`, or `nil` if the
    /// key has no value. Returns `Any?` because the bottom layer is untyped;
    /// `KeyValueStoring.loadValue<Value>` casts to the desired type for callers.
    func loadValue(for key: String) -> Any?

    /// Removes the value at `key`. No-op if the key is absent.
    func deleteValue(for key: String)
}
