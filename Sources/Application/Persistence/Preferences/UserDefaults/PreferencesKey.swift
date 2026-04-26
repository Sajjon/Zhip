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

/// Insensitive values to be stored into e.g. `UserDefaults`, such as `hasAcceptedTermsOfService`
enum PreferencesKey: String, KeyConvertible {
    /// Set to `true` after the first successful launch. Doubles as the
    /// reinstall sentinel that drives Keychain wipe — see
    /// `KeyValueStore<KeychainKey>.wallet`.
    case hasRunAppBefore
    /// User accepted the Terms of Service screen during onboarding.
    case hasAcceptedTermsOfService
    /// User accepted the "we use a custom ECC implementation" warning.
    case hasAcceptedCustomECCWarning
    /// User answered the crash-reporting opt-in prompt (`true`/`false` is in `hasAcceptedCrashReporting`).
    case hasAnsweredCrashReportingQuestion
    /// User opted in to crash reporting.
    case hasAcceptedCrashReporting
    /// User explicitly chose "skip pincode setup" — suppresses the prompt on subsequent launches.
    case skipPincodeSetup
    /// Last-known wallet balance, cached to render UI before the network call resolves.
    case cachedBalance
    /// Timestamp accompanying `cachedBalance`; used to render "updated N minutes ago" labels.
    case balanceWasUpdatedAt
}

/// Abstraction of UserDefaults
///
/// Production code injects a `Preferences` (i.e. `KeyValueStore<PreferencesKey>`)
/// resolved by `Container.shared.preferences`, which wraps `UserDefaults.standard`.
/// Tests register an in-memory replacement in `Tests/Helpers/TestStoreFactory.swift`.
typealias Preferences = KeyValueStore<PreferencesKey>
