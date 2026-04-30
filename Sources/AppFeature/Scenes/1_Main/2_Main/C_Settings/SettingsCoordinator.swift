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
import SingleLineControllerNavigation
import UIKit
import Zesame

/// Source URL the "Star us on GitHub" + "Report issue" actions open.
public let githubUrlString = "https://github.com/OpenZesame/Zhip"

/// Outcomes the Settings sub-flow surfaces to its parent (`MainCoordinator`).
public enum SettingsCoordinatorNavigationStep {
    /// User confirmed wallet removal — `MainCoordinator` should bubble this
    /// up to `AppCoordinator` to swap back to onboarding.
    case removeWallet
    /// User dismissed Settings — `MainCoordinator` closes the modal.
    case closeSettings
}

/// Coordinator owning the Settings hub and its 11+ secondary actions.
///
/// The hub itself is a single table-view scene (`Settings`); each row routes
/// to either:
/// - an external URL (GitHub, system Settings),
/// - a re-presentation of an onboarding scene in `.dismissable` mode (Terms,
///   crash-reporting, ECC warning),
/// - a sub-coordinator (set/remove pincode, backup wallet),
/// - or a confirm-and-destroy modal (remove wallet).
public final class SettingsCoordinator: BaseCoordinator<SettingsCoordinatorNavigationStep> {
    /// Used to clear the cached balance when the wallet is removed.
    @Injected(\.transactionsUseCase) private var transactionUseCase: TransactionsUseCase
    /// Used to delete the wallet on remove.
    @Injected(\.walletStorageUseCase) private var walletStorageUseCase: WalletStorageUseCase
    /// Forwarded to the pincode sub-flows + used to delete the pincode on wallet remove.
    @Injected(\.pincodeUseCase) private var pincodeUseCase: PincodeUseCase
    /// Forwarded to the re-presented onboarding scenes (Terms, crash-reporting, ECC).
    @Injected(\.onboardingUseCase) private var onboardingUseCase: OnboardingUseCase

    /// Begins by pushing the Settings hub.
    override public func start(didStart _: Completion? = nil) {
        toSettings()
    }
}

// MARK: - Navigate

private extension SettingsCoordinator {
    /// Pushes the Settings hub. Big switch routes each row tap to its handler.
    /// (cyclomatic_complexity disabled because the switch *is* the navigation
    /// table and splitting it would only fragment the discoverable router.)
    func toSettings() { // swiftlint:disable:this cyclomatic_complexity
        let viewModel = SettingsViewModel(useCase: pincodeUseCase)

        push(scene: Settings.self, viewModel: viewModel) { [weak self] userIntendsTo in
            guard let self else { return }
            switch userIntendsTo {
            // Navigation bar
            case .closeSettings: finish()
            // Section 0
            case .removePincode: toRemovePincode()
            case .setPincode: toSetPincode()
            // Section 1
            case .starUsOnGithub: toStarUsOnGitHub()
            case .reportIssueOnGithub: toReportIssueOnGithub()
            case .acknowledgments: toAcknowledgments()
            // Section 2
            case .readTermsOfService: toReadTermsOfService()
            case .changeAnalyticsPermissions: toChangeAnalyticsPermissions()
            case .readCustomECCWarning: toReadCustomECCWarning()
            // Section 3
            case .backupWallet: toBackupWallet()
            case .removeWallet: toConfirmWalletRemoval()
            }
        }
    }

    /// Modally presents the pincode-removal confirmation.
    func toRemovePincode() {
        let viewModel = RemovePincodeViewModel(useCase: pincodeUseCase)

        modallyPresent(scene: RemovePincode.self, viewModel: viewModel) { userDid, dismissScene in
            switch userDid {
            case .cancelPincodeRemoval, .removePincode: dismissScene(true, nil)
            }
        }
    }

    /// Hands off to `SetPincodeCoordinator` for the (rare) "set pincode after the fact" flow.
    func toSetPincode() {
        presentModalCoordinator(
            makeCoordinator: { SetPincodeCoordinator(
                navigationController: $0,
                useCase: pincodeUseCase
            ) },
            navigationHandler: { userDid, dismissModalFlow in
                switch userDid {
                case .setPincode: dismissModalFlow(true)
                }
            }
        )
    }

    /// Opens the GitHub repo in Safari/the user's browser.
    func toStarUsOnGitHub() {
        openUrl(string: githubUrlString)
    }

    /// Opens the GitHub "new issue" page.
    func toReportIssueOnGithub() {
        openUrl(string: githubUrlString, relative: "issues/new")
    }

    /// Opens the iOS Settings app (where Apple shows the bundled licenses).
    func toAcknowledgments() {
        openUrl(string: UIApplication.openSettingsURLString)
    }

    /// Re-presents the crash-reporting onboarding scene in dismissable mode.
    func toChangeAnalyticsPermissions() {
        let viewModel = AskForCrashReportingPermissionsViewModel(useCase: onboardingUseCase, isDismissible: true)
        let scene = AskForCrashReportingPermissions(viewModel: viewModel, navigationBarLayout: .opaque)

        modallyPresent(scene: scene) { userDid, dismissScene in
            switch userDid {
            case .answerQuestionAboutCrashReporting, .dismiss: dismissScene(true, nil)
            }
        }
    }

    /// Re-presents the Terms scene in dismissable mode.
    func toReadTermsOfService() {
        let viewModel = TermsOfServiceViewModel(useCase: onboardingUseCase, isDismissible: true)
        let termsOfService = TermsOfService(viewModel: viewModel, navigationBarLayout: .opaque)
        modallyPresent(scene: termsOfService) { userDid, dismissScene in
            switch userDid {
            case .acceptTermsOfService, .dismiss: dismissScene(true, nil)
            }
        }
    }

    /// Re-presents the ECC warning scene in dismissable mode.
    func toReadCustomECCWarning() {
        let viewModel = WarningCustomECCViewModel(
            useCase: onboardingUseCase,
            isDismissible: true
        )

        let scene = WarningCustomECC(viewModel: viewModel, navigationBarLayout: .opaque)

        modallyPresent(scene: scene) { userDid, dismissScene in
            switch userDid {
            case .acceptRisks, .dismiss: dismissScene(true, nil)
            }
        }
    }

    /// Hands off to `BackupWalletCoordinator` in `.dismissable` mode (no
    /// "I have backed up" CTA, since the wallet is already saved).
    func toBackupWallet() {
        presentModalCoordinator(
            makeCoordinator: { BackupWalletCoordinator(
                navigationController: $0,
                mode: .dismissable
            )
            },
            navigationHandler: { userFinished, dismissModalFlow in
                switch userFinished {
                case .cancel, .backUp: dismissModalFlow(true)
                }
            }
        )
    }

    /// Modally presents the wallet-removal confirmation. On confirm, dismiss
    /// then chain into the destructive cleanup so the modal animation completes
    /// before the data wipe + parent navigation kick in.
    func toConfirmWalletRemoval() {
        let viewModel = ConfirmWalletRemovalViewModel()

        modallyPresent(scene: ConfirmWalletRemoval.self, viewModel: viewModel) { userDid, dismissScene in
            switch userDid {
            case .cancel: dismissScene(true, nil)
            case .confirm:
                dismissScene(true) { [weak self] in
                    self?.toChooseWallet()
                }
            }
        }
    }

    /// Wipes balance cache + wallet keystore + pincode and bubbles `.removeWallet`
    /// to the parent so it can swap back to onboarding.
    func toChooseWallet() {
        transactionUseCase.deleteCachedBalance()
        walletStorageUseCase.deleteWallet()
        pincodeUseCase.deletePincode()
        userIntends(to: .removeWallet)
    }

    /// Bubble `.closeSettings` to the parent.
    func finish() {
        userIntends(to: .closeSettings)
    }

    /// Convenience wrapper for `navigator.next`.
    func userIntends(to intention: NavigationStep) {
        navigator.next(intention)
    }
}
