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

import Factory
import UIKit
import Zesame

/// Outcome the onboarding coordinator surfaces to its parent (`AppCoordinator`)
/// when onboarding is complete.
enum OnboardingCoordinatorNavigationStep {
    /// All required onboarding steps have been satisfied; `AppCoordinator`
    /// should transition to the `MainCoordinator`.
    case finishOnboarding
}

/// Drives the linear pre-wallet onboarding flow:
/// Welcome → Terms → Crash-reporting → ECC warning → Choose wallet → Pincode.
///
/// `toNextStep()` is the central decision tree — each onboarding fact is
/// stored in `Preferences` via `OnboardingUseCase`, so a partially-completed
/// onboarding resumes at the first unsatisfied step on next launch.
final class OnboardingCoordinator: BaseCoordinator<OnboardingCoordinatorNavigationStep> {
    /// Reads/writes the per-step "has accepted/answered" flags from `Preferences`.
    @Injected(\.onboardingUseCase) private var onboardingUseCase: OnboardingUseCase
    /// Used to skip the wallet-choose step when a wallet is already persisted.
    @Injected(\.walletStorageUseCase) private var walletStorageUseCase: WalletStorageUseCase
    /// Forwarded to the pincode sub-coordinator.
    @Injected(\.pincodeUseCase) private var pincodeUseCase: PincodeUseCase

    /// Always begins at the Welcome screen — even on subsequent launches that
    /// re-enter onboarding because a step is still missing.
    override func start(didStart _: Completion? = nil) {
        toWelcome()
    }
}

private extension OnboardingCoordinator {
    /// Pushes the welcome scene; user tap of "start" advances to `toNextStep`.
    func toWelcome() {
        push(scene: Welcome.self, viewModel: WelcomeViewModel()) { [weak self] userIntendsTo in
            switch userIntendsTo {
            case .start: self?.toNextStep()
            }
        }
    }

    /// Linear gate over the persisted onboarding facts — pushes the first
    /// scene whose precondition is unmet, or finishes if everything is done.
    /// Each `guard` represents one user-visible step.
    func toNextStep() {
        guard onboardingUseCase.hasAcceptedTermsOfService else {
            return toTermsOfService()
        }

        guard onboardingUseCase.hasAnsweredCrashReportingQuestion else {
            return toAnalyticsPermission()
        }

        guard onboardingUseCase.hasAcceptedCustomECCWarning else {
            return toCustomECCWarning()
        }

        guard walletStorageUseCase.hasConfiguredWallet else {
            return toChooseWallet()
        }

        guard !onboardingUseCase.shouldPromptUserToChosePincode else {
            return toChoosePincode()
        }

        finish()
    }

    /// Pushes the Terms of Service screen. Both `.acceptTermsOfService`
    /// (positive ack) and `.dismiss` (also recorded as accepted) advance to
    /// the next step — there is no "no" option in this onboarding.
    func toTermsOfService() {
        let viewModel = TermsOfServiceViewModel(useCase: onboardingUseCase, isDismissible: false)
        push(scene: TermsOfService.self, viewModel: viewModel) { [weak self] userDid in
            switch userDid {
            case .acceptTermsOfService, .dismiss: self?.toAnalyticsPermission()
            }
        }
    }

    /// Pushes the crash-reporting permission prompt. Either acceptance state
    /// (yes/no/dismiss) records the answer and advances to the next step.
    func toAnalyticsPermission() {
        let viewModel = AskForCrashReportingPermissionsViewModel(useCase: onboardingUseCase, isDismissible: false)

        push(scene: AskForCrashReportingPermissions.self, viewModel: viewModel) { [weak self] userDid in
            switch userDid {
            case .answerQuestionAboutCrashReporting, .dismiss: self?.toCustomECCWarning()
            }
        }
    }

    /// Pushes the "this app uses a custom ECC implementation, here be dragons"
    /// warning. Acceptance is required to proceed to wallet creation.
    func toCustomECCWarning() {
        let viewModel = WarningCustomECCViewModel(
            useCase: onboardingUseCase,
            isDismissible: false
        )

        push(scene: WarningCustomECC.self, viewModel: viewModel) { [weak self] userDid in
            switch userDid {
            case .acceptRisks, .dismiss: self?.toChooseWallet()
            }
        }
    }

    /// Hands off to `ChooseWalletCoordinator` (create new vs restore existing).
    /// On completion, advances to pincode setup.
    func toChooseWallet() {
        let coordinator = ChooseWalletCoordinator(
            navigationController: navigationController
        )

        start(coordinator: coordinator) { [weak self] in
            switch $0 {
            case .finishChoosingWallet: self?.toChoosePincode()
            }
        }
    }

    /// Hands off to `SetPincodeCoordinator`. The pincode sub-flow can also
    /// be skipped (recorded in `Preferences`); either outcome finishes onboarding.
    func toChoosePincode() {
        start(
            coordinator: SetPincodeCoordinator(
                navigationController: navigationController,
                useCase: pincodeUseCase
            )
        ) { [weak self] (userDid: SetPincodeCoordinatorNavigationStep) in
            switch userDid {
            case .setPincode: self?.finish()
            }
        }
    }

    /// Emits `.finishOnboarding` to the parent so it can swap to the main flow.
    func finish() {
        navigator.next(.finishOnboarding)
    }
}
