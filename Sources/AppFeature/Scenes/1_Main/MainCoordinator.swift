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

import Combine
import Factory
import NanoViewControllerCombine
import NanoViewControllerNavigation
import UIKit
import Zesame

/// Outcome the main coordinator surfaces to its parent (`AppCoordinator`).
public enum MainCoordinatorNavigationStep: Sendable {
    /// User confirmed wallet removal in Settings — `AppCoordinator` should
    /// transition back to onboarding.
    case removeWallet
}

/// Coordinator owning the post-onboarding "main" experience: the wallet hub
/// (`Main`) plus three modal sub-flows (Send, Receive, Settings).
///
/// Also handles the universal-link `send` deep link by presenting the Send
/// flow with a pre-filled transaction.
public final class MainCoordinator: BaseCoordinator<MainCoordinatorNavigationStep> {
    /// Stream of incoming deep-linked transactions (replays the latest if a deep
    /// link arrived before a coordinator was ready).
    private let deeplinkedTransaction: AnyPublisher<TransactionIntent, Never>
    /// Triggered after a successful Send flow so the Main scene refetches balance.
    private let updateBalanceSubject = PassthroughSubject<Void, Never>()

    /// Captures the navigation controller + deep-link source. Subscribes to the
    /// deep-link stream so an inbound `send/...` URL automatically opens the
    /// Send flow (when no other modal is up).
    init(
        navigationController: UINavigationController,
        deeplinkedTransaction: AnyPublisher<TransactionIntent, Never>
    ) {
        self.deeplinkedTransaction = deeplinkedTransaction
        super.init(navigationController: navigationController)
        deeplinkedTransaction.mapToVoid().sink { [weak self] in self?.toSendPrefilTransaction() }
            .store(in: &cancellables)
    }

    /// Begins by pushing the Main hub.
    override public func start(didStart: Completion? = nil) {
        toMain(didStart: didStart)
    }
}

//// MARK: - Deep Link Navigation
private extension MainCoordinator {
    /// Opens the Send flow if no modal sub-flow is currently active.
    /// Avoids stacking modals when the user has e.g. Settings open.
    func toSendPrefilTransaction() {
        guard childCoordinators.isEmpty else {
            // Prevented navigation to PrepareTransaction via deeplink since a coordinator is already presented
            return
        }
        toSend()
    }
}

// MARK: - Navigation

private extension MainCoordinator {
    /// Pushes the Main hub. Wires the three CTAs (send/receive/settings) to
    /// their respective modal sub-flows.
    func toMain(didStart: Completion? = nil) {
        let viewModel = MainViewModel(
            updateBalanceTrigger: updateBalanceSubject.replaceErrorWithEmpty().eraseToAnyPublisher()
        )

        push(
            scene: Main.self,
            viewModel: viewModel,
            navigationPresentationCompletion: didStart
        ) { [weak self] userIntendsTo in
            guard let self else { return }
            switch userIntendsTo {
            case .send: toSend()
            case .receive: toReceive()
            case .goToSettings: toSettings()
            }
        }
    }

    /// Presents the Send sub-coordinator modally. On finish (with the
    /// "balance changed" flag set) trigger a refetch on the Main hub.
    func toSend() {
        presentModalCoordinator(
            makeCoordinator: { SendCoordinator(
                navigationController: $0,
                deeplinkedTransaction: deeplinkedTransaction
            )
            },
            navigationHandler: { [weak self] userDid, dismissModalFlow in
                switch userDid {
                case let .finish(triggerBalanceFetching):
                    if triggerBalanceFetching {
                        self?.triggerFetchingOfBalance()
                    }
                    dismissModalFlow(true)
                }
            }
        )
    }

    /// Presents the Receive (QR-code) sub-coordinator modally.
    func toReceive() {
        presentModalCoordinator(
            makeCoordinator: { ReceiveCoordinator(navigationController: $0) },
            navigationHandler: { userIntendsTo, dismissModalFlow in
                switch userIntendsTo {
                case .finish: dismissModalFlow(true)
                }
            }
        )
    }

    /// Presents the Settings sub-coordinator modally. `.removeWallet` bubbles
    /// up to the parent so it can transition back to onboarding.
    func toSettings() {
        presentModalCoordinator(
            makeCoordinator: { SettingsCoordinator(navigationController: $0) },
            navigationHandler: { [weak self] userIntendsTo, dismissModalFlow in
                switch userIntendsTo {
                case .removeWallet: self?.navigator.next(.removeWallet)
                case .closeSettings: dismissModalFlow(true)
                }
            }
        )
    }
}

// MARK: - Private

private extension MainCoordinator {
    /// Pushes a void pulse onto `updateBalanceSubject` so the Main hub refetches.
    func triggerFetchingOfBalance() {
        updateBalanceSubject.send(())
    }
}
