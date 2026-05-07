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

// MARK: - Narrow use cases (one per onboarding step)

/// Tracks whether the user has accepted the Terms of Service.
public protocol TermsOfServiceAcceptanceUseCase: AnyObject {
    /// `true` once the user has accepted the Terms of Service.
    var hasAcceptedTermsOfService: Bool { get }

    /// Records that the user has accepted the Terms of Service.
    func didAcceptTermsOfService()
}

/// Computes whether the user should be prompted to choose an app pincode.
public protocol PincodePromptUseCase: AnyObject {
    /// `true` if the app should prompt the user to set up a pincode during onboarding.
    var shouldPromptUserToChosePincode: Bool { get }
}

// MARK: - Composite façade (backward-compatibility)

/// Composite onboarding protocol retained for backwards compatibility with existing
/// call sites. Prefer the narrow protocols above in new code.
public protocol OnboardingUseCase: TermsOfServiceAcceptanceUseCase, PincodePromptUseCase {}
