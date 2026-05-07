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

// MARK: - Narrow use cases (split from the old monolithic `PincodeUseCase`)

/// Reads the pincode stored in secure storage and whether one has ever been chosen.
public protocol PincodeReadUseCase: AnyObject {
    /// The currently-configured pincode, or `nil` if none has been set.
    var pincode: Pincode? { get }

    /// `true` if the user has previously set a pincode.
    var hasConfiguredPincode: Bool { get }
}

/// Writes or deletes the stored pincode, and records a "skip setup" preference.
public protocol PincodeWriteUseCase: AnyObject {
    /// Persists the user-chosen `pincode` to secure storage.
    func userChoose(pincode: Pincode)

    /// Marks the one-time onboarding pincode prompt as dismissed, so we don't prompt
    /// again on subsequent launches.
    func skipSettingUpPincode()

    /// Removes any persisted pincode and clears the "skip setup" preference.
    func deletePincode()
}

// MARK: - Composite façade (backward-compatibility)

/// Composite pincode protocol retained for backwards compatibility with existing
/// call sites. Prefer the narrow protocols above in new code.
public protocol PincodeUseCase: PincodeReadUseCase, PincodeWriteUseCase {}
