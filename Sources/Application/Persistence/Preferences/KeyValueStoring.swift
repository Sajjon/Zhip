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

/// A typed simple, non thread safe, non async key-value store accessing values using its associatedtype `Key`
///
/// Layered on top of `AnyKeyValueStoring` so the typed methods can delegate to
/// the string-keyed primitives below without re-implementing each backend.
protocol KeyValueStoring: AnyKeyValueStoring {
    /// Strongly-typed key (typically a `String`-backed enum) that this store accepts.
    associatedtype Key: KeyConvertible

    /// Persists `value` under `key`. See `AnyKeyValueStoring.save(value:for:)`.
    func save(value: Any, for key: Key)

    /// Retrieves and casts the value at `key` to `Value`, or `nil` on miss/cast-failure.
    func loadValue<Value>(for key: Key) -> Value?

    /// Removes the value at `key`. No-op if absent.
    func deleteValue(for key: Key)
}

// MARK: Default Implementation making use of `AnyKeyValueStoring` protocol

extension KeyValueStoring {
    /// Default impl that simply unwraps `key` to its string form and delegates
    /// to the type-erased `AnyKeyValueStoring` member.
    func save(value: Any, for key: Key) {
        save(value: value, for: key.key)
    }

    /// Default impl that loads the raw `Any?` and tries to cast to `Value`.
    /// Returns `nil` if the key is absent OR the stored value is the wrong type.
    func loadValue<Value>(for key: Key) -> Value? {
        guard let value = loadValue(for: key.key), let typed = value as? Value else { return nil }
        return typed
    }

    /// Default impl that simply forwards to the type-erased `deleteValue(for:)`.
    func deleteValue(for key: Key) {
        deleteValue(for: key.key)
    }
}

// MARK: - Codable

extension KeyValueStoring {
    /// Decodes a JSON `Data` blob previously written by `saveCodable(_:for:)`.
    /// - Returns: The decoded model, or `nil` if the key is absent or the data is malformed.
    func loadCodable<C: Codable>(_: C.Type, for key: Key) -> C? {
        guard
            let json: Data = loadValue(for: key),
            let model = try? JSONDecoder().decode(C.self, from: json)
        else { return nil }
        return model
    }

    /// JSON-encodes `model` and stores the resulting `Data` under `key`.
    ///
    /// Failures are logged and silently swallowed — the persistence layer is
    /// best-effort, and a Codable encoding failure here would indicate a bug
    /// (Codable types we author should always round-trip).
    func saveCodable(_ model: some Codable, for key: Key) {
        let encoder = JSONEncoder()
        do {
            let json = try encoder.encode(model)
            save(value: json, for: key)
        } catch {
            log.error("Failed to save codable")
        }
    }
}

// MARK: Convenience

extension KeyValueStoring {
    /// `true` iff a `Bool` is stored at `key` and equals `true`.
    /// Absent or wrong-typed values count as `false` (matches UserDefaults semantics).
    func isTrue(_ key: Key) -> Bool {
        guard let bool: Bool = loadValue(for: key) else { return false }
        return bool == true
    }

    /// Logical negation of `isTrue(_:)` — including the "absent" case.
    func isFalse(_ key: Key) -> Bool {
        !isTrue(key)
    }
}
