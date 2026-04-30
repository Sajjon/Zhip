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

/// Type used as a key to some value, e.g. a wrapper around `UserDefaults`
///
/// Both `PreferencesKey` (for `UserDefaults`) and `KeychainKey` (for the
/// Keychain) are `String`-backed enums conforming to this protocol. The default
/// extension below makes the `key` property "free" for any such enum.
public protocol KeyConvertible {
    /// The underlying string used by the storage backend as the lookup key.
    var key: String { get }
}

// MARK: - Default Implementation for `enum SomeKey: String`

extension KeyConvertible where Self: RawRepresentable, Self.RawValue == String {
    /// Default impl that simply forwards to the enum's raw value, so
    /// `.hasRunAppBefore` becomes `"hasRunAppBefore"` automatically.
    public var key: String {
        rawValue
    }
}
