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

/// Default implementation of the composite `PincodeUseCase` and the two narrow
/// protocols it composes (`PincodeReadUseCase`, `PincodeWriteUseCase`).
///
/// Pincode bytes live in the secure (Keychain) store; the "user has opted out of
/// pincode setup" preference lives in UserDefaults because losing it on reinstall
/// is fine.
public final class DefaultPincodeUseCase {
    /// Non-secret key-value store used only to remember the "skip pincode setup"
    /// preference.
    private let preferences: Preferences

    /// Secret key-value store holding the serialized pincode bytes.
    let securePersistence: SecurePersistence

    /// Designated initializer.
    init(preferences: Preferences, securePersistence: SecurePersistence) {
        self.preferences = preferences
        self.securePersistence = securePersistence
    }
}

extension DefaultPincodeUseCase: PincodeUseCase {
    /// Marks the onboarding pincode prompt as dismissed so we don't prompt again
    /// on subsequent launches.
    public func skipSettingUpPincode() {
        preferences.save(value: true, for: .skipPincodeSetup)
    }

    /// The currently-configured pincode, or `nil` if none has been set.
    public var pincode: Pincode? {
        securePersistence.loadCodable(Pincode.self, for: .pincodeProtectingAppThatHasNothingToDoWithCryptography)
    }

    /// `true` if the user has previously set a pincode.
    public var hasConfiguredPincode: Bool {
        securePersistence.hasConfiguredPincode
    }

    /// Removes any persisted pincode and clears the "skip setup" preference so
    /// subsequent launches prompt again.
    public func deletePincode() {
        preferences.deleteValue(for: .skipPincodeSetup)
        securePersistence.deleteValue(for: .pincodeProtectingAppThatHasNothingToDoWithCryptography)
    }

    /// Persists the user-chosen `pincode` to secure storage.
    public func userChoose(pincode: Pincode) {
        securePersistence.save(pincode: pincode)
    }
}
