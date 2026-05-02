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

// MARK: - Narrow use cases (one per onboarding step)

/// Tracks whether the user has accepted the Terms of Service.
public protocol TermsOfServiceAcceptanceUseCase: AnyObject {
    /// `true` once the user has accepted the Terms of Service.
    var hasAcceptedTermsOfService: Bool { get }

    /// Records that the user has accepted the Terms of Service.
    func didAcceptTermsOfService()
}

/// Tracks whether the user has read and accepted the custom ECC warning.
public protocol CustomECCWarningAcceptanceUseCase: AnyObject {
    /// `true` once the user has acknowledged the custom ECC warning.
    var hasAcceptedCustomECCWarning: Bool { get }

    /// Records that the user has acknowledged the custom ECC warning.
    func didAcceptCustomECCWarning()
}

/// Tracks whether the user has answered the crash-reporting opt-in prompt.
public protocol CrashReportingPermissionsUseCase: AnyObject {
    /// `true` once the user has answered the crash-reporting prompt at least once.
    var hasAnsweredCrashReportingQuestion: Bool { get }

    /// Records the user's answer (`true` for opt-in) and configures crash reporting
    /// accordingly.
    func answeredCrashReportingQuestion(acceptsCrashReporting: Bool)
}

/// Computes whether the user should be prompted to choose an app pincode.
public protocol PincodePromptUseCase: AnyObject {
    /// `true` if the app should prompt the user to set up a pincode during onboarding.
    var shouldPromptUserToChosePincode: Bool { get }
}

// MARK: - Composite façade (backward-compatibility)

/// Composite onboarding protocol retained for backwards compatibility with existing
/// call sites. Prefer the narrow protocols above in new code.
public protocol OnboardingUseCase: TermsOfServiceAcceptanceUseCase,
    CustomECCWarningAcceptanceUseCase,
    CrashReportingPermissionsUseCase,
    PincodePromptUseCase {}
