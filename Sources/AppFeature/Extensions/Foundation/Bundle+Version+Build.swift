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

extension Bundle {
    /// Logical names for the `Info.plist` keys this extension reads.
    /// The raw value is the key suffix; `key` prepends the `CFBundle` prefix
    /// to produce the actual `Info.plist` key.
    enum Key: String {
        /// Maps to `CFBundleShortVersionString` — the user-visible "1.2.3" version.
        case shortVersionString
        /// Maps to `CFBundleVersion` — the build number that increments per build.
        case version
        /// Maps to `CFBundleName` — the bundle's display name.
        case name

        /// Composes the actual `Info.plist` key by prepending `CFBundle` to the
        /// capitalised raw value (`shortVersionString` → `CFBundleShortVersionString`).
        var key: String {
            "CFBundle\(rawValue.capitalizingFirstLetter())"
        }
    }

    /// User-visible marketing version (e.g. "1.4.2").
    var version: String? {
        valueBy(key: .shortVersionString)
    }

    /// Build number (e.g. "732"). Note: `CFBundleVersion` historically holds the
    /// *build* number, while `CFBundleShortVersionString` holds the marketing
    /// version — naming inverse of intuition, hence the explicit accessors above.
    var build: String? {
        valueBy(key: .version)
    }

    /// Bundle display name from `CFBundleName`.
    var name: String? {
        valueBy(key: .name)
    }

    /// Convenience that maps a `Key` enum value to the underlying string lookup.
    func valueBy(key: Key) -> String? {
        let stringKey = key.key
        return value(of: stringKey)
    }

    /// Reads a string value from `infoDictionary`, returning `nil` for either a
    /// missing key or a value of the wrong type.
    func value(of key: String) -> String? {
        guard
            let info = infoDictionary,
            let value = info[key] as? String
        else { return nil }
        return value
    }
}

extension String {
    /// Returns a copy of this string with the first character upper-cased and
    /// the remainder unchanged. Useful when composing identifiers/keys
    /// (see `Bundle.Key.key`).
    func capitalizingFirstLetter() -> String {
        prefix(1).uppercased() + dropFirst()
    }

    /// In-place variant of `capitalizingFirstLetter()`.
    mutating func capitalizeFirstLetter() {
        self = capitalizingFirstLetter()
    }
}
