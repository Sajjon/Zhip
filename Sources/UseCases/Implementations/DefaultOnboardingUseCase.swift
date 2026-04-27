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
import Zesame

/// Default implementation of the composite `OnboardingUseCase` and all four
/// narrow onboarding protocols it composes.
///
/// State is split across two stores: user-visible flags (terms, ECC warning,
/// crash reporting answers) live in `preferences` (UserDefaults); sensitive
/// pincode existence is inferred from `securePersistence` (Keychain).
final class DefaultOnboardingUseCase {
    /// Non-secret key-value store (backed by `UserDefaults` in production).
    private let preferences: Preferences

    /// Secret key-value store (backed by Keychain in production). Only read to
    /// detect whether a pincode has been configured.
    let securePersistence: SecurePersistence

    /// Reactive Zesame façade. Held for future onboarding flows; not used by the
    /// current implementation.
    private let zilliqaService: ZilliqaServiceReactive

    /// Designated initializer. Inject stand-ins in tests to make the use case
    /// fully deterministic.
    init(zilliqaService: ZilliqaServiceReactive, preferences: Preferences, securePersistence: SecurePersistence) {
        self.zilliqaService = zilliqaService
        self.preferences = preferences
        self.securePersistence = securePersistence
    }
}

extension DefaultOnboardingUseCase: OnboardingUseCase {
    /// `true` once the user has accepted the Terms of Service.
    var hasAcceptedTermsOfService: Bool {
        preferences.isTrue(.hasAcceptedTermsOfService)
    }

    /// `true` once the user has answered the crash-reporting prompt at least once.
    var hasAnsweredCrashReportingQuestion: Bool {
        preferences.isTrue(.hasAnsweredCrashReportingQuestion)
    }

    /// Records that the user has accepted the Terms of Service.
    func didAcceptTermsOfService() {
        preferences.save(value: true, for: .hasAcceptedTermsOfService)
    }

    /// `true` once the user has acknowledged the custom ECC warning.
    var hasAcceptedCustomECCWarning: Bool {
        preferences.isTrue(.hasAcceptedCustomECCWarning)
    }

    /// Records that the user has acknowledged the custom ECC warning.
    func didAcceptCustomECCWarning() {
        preferences.save(value: true, for: .hasAcceptedCustomECCWarning)
    }

    /// Persists the crash-reporting answer (both the "has answered" flag and the
    /// `acceptsCrashReporting` value itself) and configures Firebase accordingly.
    func answeredCrashReportingQuestion(acceptsCrashReporting: Bool) {
        preferences.save(value: true, for: .hasAnsweredCrashReportingQuestion)
        preferences.save(value: acceptsCrashReporting, for: .hasAcceptedCrashReporting)
        setupCrashReportingIfAllowed()
    }

    /// `true` if onboarding should prompt the user to set up a pincode. `false`
    /// when the user has either configured one already or opted out via the
    /// `.skipPincodeSetup` preference.
    var shouldPromptUserToChosePincode: Bool {
        guard preferences.isFalse(.skipPincodeSetup) else { return false }
        return !securePersistence.hasConfiguredPincode
    }
}
