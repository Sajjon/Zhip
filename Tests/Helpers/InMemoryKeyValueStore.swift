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

@testable import AppFeature
import Foundation

/// In-memory backing for `KeyValueStoring`, used by tests to build mock
/// `Preferences` / `SecurePersistence` instances without touching UserDefaults or
/// the Keychain.
///
/// Wrap it with `KeyValueStore(InMemoryKeyValueStore<PreferencesKey>())` or
/// `KeyValueStore(InMemoryKeyValueStore<KeychainKey>())` to get a drop-in replacement
/// for the production stores.
final class InMemoryKeyValueStore<KeyType: KeyConvertible>: KeyValueStoring {
    typealias Key = KeyType

    /// Backing dictionary keyed by the string form of `Key`.
    private var storage: [String: Any] = [:]

    /// Creates an empty in-memory store.
    init() {}

    /// Preloads the store with `initial` entries (string-keyed for convenience).
    init(initial: [String: Any]) {
        storage = initial
    }

    func save(value: Any, for key: String) {
        storage[key] = value
    }

    func loadValue(for key: String) -> Any? {
        storage[key]
    }

    func deleteValue(for key: String) {
        storage.removeValue(forKey: key)
    }

    /// Direct access for test assertions (read-only snapshot).
    var _allEntries: [String: Any] {
        storage
    }
}
