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

import Combine
import Foundation
import SingleLineControllerCombine
import SingleLineControllerController
import SingleLineControllerCore
import SingleLineControllerSceneViews
import UIKit
import Zesame

/// Cell model used for every Settings row — wraps a navigation destination
/// with the row's title + icon + style.
public typealias SettingsItem = NavigatingCellModel<SettingsViewModel.NavigationStep>

// MARK: SettingsNavigation

/// Every navigation step the Settings hub can emit. Grouped by the section
/// they live in for readability.
public enum SettingsNavigation {
    /// Navigation Bar — right "Done" tap.
    case closeSettings

    /// Section 0 — Pincode management.
    case removePincode, setPincode

    // Section 1 — Community / acknowledgments.
    case starUsOnGithub
    case reportIssueOnGithub
    case acknowledgments

    // Section 2 — Re-read onboarding scenes.
    case readTermsOfService
    case readCustomECCWarning
    case changeAnalyticsPermissions

    // Section 3 — Wallet management (destructive at the bottom).
    case backupWallet
    case removeWallet
}

// MARK: SettingsViewModel

/// View model for the Settings hub. Builds the row matrix from per-section
/// `SettingsItem` arrays and routes selections to the matching `NavigationStep`.
/// Re-emits the matrix on every `viewWillAppear` so the pincode row reflects
/// the current "has pincode" state when the user returns from a sub-flow.
public final class SettingsViewModel: BaseViewModel<
    SettingsNavigation,
    SettingsViewModel.InputFromView,
    SettingsViewModel.Output
> {
    /// Used to gate the pincode row (set vs remove) on the current pincode state.
    private let useCase: PincodeUseCase

    /// Captures the pincode use case.
    init(useCase: PincodeUseCase) {
        self.useCase = useCase
    }

    /// Wires the section emission, row-tap → navigation step, and the
    /// done bar-button → close.
    override public func transform(input: Input) -> Output {
        func userWantsToNavigate(to intention: NavigationStep) {
            navigator.next(intention)
        }

        let sections: AnyPublisher<[SectionModel<Void, SettingsItem>], Never> = input.fromController.viewWillAppear
            .map { [weak self] _ in self?.makeSections() ?? [] }
            .eraseToAnyPublisher()

        let selectedCell: AnyPublisher<SettingsItem, Never> = input.fromView.selectedIndexPath
            .withLatestFrom(sections) {
                $1[$0.section].items[$0.row]
            }
            .eraseToAnyPublisher()

        [
            input.fromController.rightBarButtonTrigger
                .sink { userWantsToNavigate(to: .closeSettings) },

            selectedCell.sink {
                userWantsToNavigate(to: $0.destination)
            },
        ].forEach { $0.store(in: &cancellables) }

        return Output(
            sections: sections,
            footerText: .just(appVersionString)
        )
    }
}

public extension SettingsViewModel {
    /// User-event publishers the view-model consumes.
    struct InputFromView {
        /// Fires when the user taps a row.
        let selectedIndexPath: AnyPublisher<IndexPath, Never>
    }

    /// Reactive bindings the view installs.
    struct Output {
        /// Drives the diffable data source.
        let sections: AnyPublisher<[SectionModel<Void, SettingsItem>], Never>
        /// "AppName vX.Y.Z (build) — network: …" footer text.
        let footerText: AnyPublisher<String, Never>
    }
}

private extension SettingsViewModel {
    /// Builds the `[[SettingsItem]]` matrix in a single pass. The pincode
    /// section's first row swaps between "Set pincode" and "Remove pincode"
    /// based on `useCase.hasConfiguredPincode`.
    func makeItemMatrix() -> [[SettingsItem]] {
        var sections = [[SettingsItem]]()
        let hasPin = useCase.hasConfiguredPincode

        sections += [
            .whenSelectedNavigate(
                to: hasPin ? .removePincode : .setPincode,
                titled: hasPin ? String(localized: .Settings.removePincode) : String(localized: .Settings.setPincode),
                icon: hasPin ? UIImage(resource: .delete) : UIImage(resource: .pinCode),
                style: hasPin ? .destructive : .normal
            ),
        ]

        sections += [
            .whenSelectedNavigate(
                to: .starUsOnGithub,
                titled: String(localized: .Settings.starUsOnGithub),
                icon: UIImage(resource: .githubStar)
            ),
            .whenSelectedNavigate(
                to: .reportIssueOnGithub,
                titled: String(localized: .Settings.reportIssueOnGithub),
                icon: UIImage(resource: .githubIssue)
            ),
            .whenSelectedNavigate(
                to: .acknowledgments,
                titled: String(localized: .Settings.acknowledgements),
                icon: UIImage(resource: .cup)
            ),
        ]

        sections += [
            .whenSelectedNavigate(
                to: .readTermsOfService,
                titled: String(localized: .Settings.termsOfService),
                icon: UIImage(resource: .document)
            ),
            .whenSelectedNavigate(
                to: .changeAnalyticsPermissions,
                titled: String(localized: .Settings.crashReportingPermissions),
                icon: UIImage(resource: .analyticsSmall)
            ),
            .whenSelectedNavigate(
                to: .readCustomECCWarning,
                titled: String(localized: .Settings.readCustomECCWarning),
                icon: UIImage(resource: .ECC)
            ),
        ]

        sections += [
            .whenSelectedNavigate(
                to: .backupWallet,
                titled: String(localized: .Settings.backupWallet),
                icon: UIImage(resource: .backUp)
            ),
            .whenSelectedNavigate(
                to: .removeWallet,
                titled: String(localized: .Settings.removeWallet),
                icon: UIImage(resource: .delete),
                style: .destructive
            ),
        ]

        return sections
    }

    /// Wraps each row array in a `SectionModel` with a void section header
    /// (the table-view backing produces grouped section dividers without explicit headers).
    func makeSections() -> [SectionModel<Void, SettingsItem>] {
        makeItemMatrix().map { array in SectionModel(model: (), items: array) }
    }

    /// "AppName vVersion (Build) — network: …" footer text.
    /// Crashes (`incorrectImplementation`) if Info.plist is missing one of the
    /// three required keys — that would indicate a build-config mistake.
    var appVersionString: String {
        let bundle = Bundle.main
        guard
            let version = bundle.version,
            let build = bundle.build,
            let appName = bundle.name
        else { incorrectImplementation("Should be able to read name, version and build number") }

        let networkDisplayName = network.displayName
        return "\(appName) v\(version) (\(build))\n\(String(localized: .Settings.networkFooter(network: networkDisplayName)))"
    }
}

private extension Network {
    /// Lowercase string for the Settings footer ("mainnet" / "testnet").
    var displayName: String {
        switch self {
        case .mainnet: "mainnet"
        case .testnet: "testnet"
        }
    }
}
