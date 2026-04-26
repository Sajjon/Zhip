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
import KeychainSwift

/// Adapts the third-party `KeychainSwift` library to our `KeyValueStoring`
/// protocol so the rest of the app can ignore the Keychain SDK entirely.
extension KeychainSwift: KeyValueStoring {
    /// We only ever use this conformance with `KeychainKey`; surfaces here for
    /// the strongly-typed default extension methods on `KeyValueStoring`.
    typealias Key = KeychainKey

    /// Tries each `KeychainSwift` accessor in turn — `Data`, `Bool`, `String` —
    /// since the underlying Keychain item could be any of them.
    ///
    /// **INVARIANT — must be preserved**: each `KeychainKey` is always written
    /// with one specific value type for the *lifetime* of the key. We rely on
    /// this because `KeychainSwift` stores `Bool`/`String` internally as raw
    /// bytes, so `getData` would *also* return non-nil for keys that were
    /// written as `Bool`/`String` — it would just hand back the underlying
    /// representation rather than the typed value. The `getData → getBool →
    /// get` ordering here is "safe" only because no key is read with a type
    /// other than the one it was written with.
    ///
    /// If you ever introduce a `KeychainKey` that needs to be read as a
    /// different type than it was written, switch to a length-prefixed type
    /// tag in the value blob — don't try to disambiguate by accessor order.
    func loadValue(for key: String) -> Any? {
        if let data = getData(key) {
            data
        } else if let bool = getBool(key) {
            bool
        } else if let string = get(key) {
            string
        } else {
            nil
        }
    }

    /// Saves items in Keychain using access option `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly`
    /// Do not that means that if the user unsets the iOS passcode for their iOS device, then all data
    /// will be lost, read more:
    /// https://developer.apple.com/documentation/security/ksecattraccessiblewhenpasscodesetthisdeviceonly
    func save(value: Any, for key: String) {
        let access: KeychainSwiftAccessOptions = .accessibleWhenPasscodeSetThisDeviceOnly
        // Mirrors the type-discrimination in `loadValue(for:)`. Anything that
        // isn't `Data`/`Bool`/`String` is silently dropped — wallet JSON arrives
        // here as `Data`, pincode booleans as `Bool`.
        if let data = value as? Data {
            set(data, forKey: key, withAccess: access)
        } else if let bool = value as? Bool {
            set(bool, forKey: key, withAccess: access)
        } else if let string = value as? String {
            set(string, forKey: key, withAccess: access)
        }
    }

    /// Removes the Keychain item at `key`. No-op if absent.
    func deleteValue(for key: String) {
        delete(key)
    }
}
