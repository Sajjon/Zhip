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
@testable import Zhip

/// Convenience factories to produce test-friendly `Preferences` and
/// `SecurePersistence` instances backed by `InMemoryKeyValueStore`.
enum TestStoreFactory {

    /// Builds an isolated `Preferences` backed by an empty in-memory store.
    static func makePreferences() -> Preferences {
        KeyValueStore(InMemoryKeyValueStore<PreferencesKey>())
    }

    /// Builds an isolated `SecurePersistence` backed by an empty in-memory store.
    ///
    /// (Previously this helper had to pre-seed `hasRunAppBefore` because the
    /// `KeyValueStore.wallet` getter had a destructive reinstall-detect side
    /// effect that hard-referenced `Preferences.default`. The reinstall logic
    /// now lives in `wipeStaleKeychainOnReinstallIfNeeded()` in Bootstrap and
    /// is only invoked from production launch — tests never trigger it.)
    static func makeSecurePersistence() -> SecurePersistence {
        KeyValueStore(InMemoryKeyValueStore<KeychainKey>())
    }
}
