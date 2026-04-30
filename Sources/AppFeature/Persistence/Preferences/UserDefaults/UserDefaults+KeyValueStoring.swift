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

// MARK: - KeyValueStoring

/// Adapts Foundation's `UserDefaults` to our `KeyValueStoring` protocol.
///
/// `Container.shared.preferences` wraps `UserDefaults.standard` in a
/// `KeyValueStore<PreferencesKey>` so insensitive flags (terms accepted,
/// cached balance, etc.) can be read/written through the same protocol used
/// for the Keychain.
extension UserDefaults: KeyValueStoring {
    /// Removes the value at `key` via `removeObject(forKey:)`.
    public func deleteValue(for key: String) {
        removeObject(forKey: key)
    }

    /// We only ever use this conformance with `PreferencesKey`.
    public typealias Key = PreferencesKey

    /// Persists `value` via `setValue(_:forKey:)` — `UserDefaults` accepts any
    /// plist-compatible value (`Bool`, `Int`, `String`, `Data`, `Date`, etc.).
    public func save(value: Any, for key: String) {
        setValue(value, forKey: key)
    }

    /// Retrieves the raw `Any?` previously written under `key`, or `nil` if absent.
    public func loadValue(for key: String) -> Any? {
        value(forKey: key)
    }
}
