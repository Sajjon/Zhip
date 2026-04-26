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
import Factory
import Zesame

// MARK: - MainUserAction

/// Outcomes of the wallet hub.
enum MainUserAction {
    /// User tapped the Send CTA.
    case send
    /// User tapped the Receive CTA.
    case receive
    /// User tapped the right-bar settings cog.
    case goToSettings
}

// MARK: - MainViewModel

/// View model for the wallet hub. Manages three independent triggers that
/// fire a balance refetch (initial load, pull-to-refresh, post-send refresh)
/// and surfaces formatted balance + freshness label to the view.
final class MainViewModel: BaseViewModel<
    MainUserAction,
    MainViewModel.InputFromView,
    MainViewModel.Output
> {
    /// Network + cache façade for balance/gas-price calls.
    @Injected(\.transactionsUseCase) private var transactionUseCase: TransactionsUseCase
    /// Wallet source — resolves to the persisted wallet.
    @Injected(\.walletStorageUseCase) private var walletStorageUseCase: WalletStorageUseCase

    /// External pulse that asks for a refetch — e.g. the post-send hook from
    /// `MainCoordinator.triggerFetchingOfBalance()`.
    private let updateBalanceTrigger: AnyPublisher<Void, Never>

    // MARK: - Initialization

    /// Captures the external balance-refresh trigger.
    init(updateBalanceTrigger: AnyPublisher<Void, Never>) {
        self.updateBalanceTrigger = updateBalanceTrigger
    }

    /// Composes the three refetch triggers, runs the balance use case,
    /// caches the result, and surfaces formatted balance + freshness.
    override func transform(input: Input) -> Output {
        func userIntends(to intention: NavigationStep) {
            navigator.next(intention)
        }

        let wallet = walletStorageUseCase.wallet.filterNil().replaceErrorWithEmpty()

        let activityIndicator = ActivityIndicator()

        // Three triggers fan into a single fetch stream:
        //   - external (post-send) → updateBalanceTrigger
        //   - user-initiated → pullToRefreshTrigger
        //   - initial load → wallet emission
        let fetchTrigger = Publishers.Merge3(updateBalanceTrigger, input.fromView.pullToRefreshTrigger, wallet.mapToVoid()).eraseToAnyPublisher()

        // Run the balance call. flatMapLatest cancels in-flight requests when
        // a new trigger fires (e.g. user pulls again before the first fetch returns).
        // handleEvents caches the balance for the next launch's pre-fetch UI.
        let latestBalanceAndNonce: AnyPublisher<BalanceResponse, Never> = fetchTrigger.withLatestFrom(wallet)
            .flatMapLatest { [unowned self] in
                self.transactionUseCase
                    .getBalance(for: $0.legacyAddress)
                    .trackActivity(activityIndicator)
                    .replaceErrorWithEmpty()
                    .handleEvents(receiveOutput: { [unowned self] in self.transactionUseCase.cacheBalance($0.balance) })
            }
            .eraseToAnyPublisher()

        // Sample balanceUpdatedAt at fetch time for the "Updated N min ago" label.
        let balanceWasUpdatedAt = fetchTrigger.map { [unowned self] in
            self.transactionUseCase.balanceUpdatedAt
        }

        // Format output
        // Show the cached balance immediately on first launch so the user
        // doesn't see a "0 ZIL" flash before the network call resolves.
        let _cachedBalance: Amount = transactionUseCase.cachedBalance ?? 0
        let latestBalanceOrZero = latestBalanceAndNonce.map(\.balance).prepend(_cachedBalance)

        [
            input.fromController.rightBarButtonTrigger
                .sink { userIntends(to: .goToSettings) },

            input.fromView.sendTrigger
                .sink { userIntends(to: .send) },

            input.fromView.receiveTrigger
                .sink { userIntends(to: .receive) },

            // Pre-warm the gas-price cache so the Send screen has a value ready.
            transactionUseCase.getMinimumGasPrice().sink(receiveCompletion: { _ in }, receiveValue: { _ in }),
        ].forEach { $0.store(in: &cancellables) }

        let formatter = AmountFormatter()

        let refreshControlLastUpdatedTitle: AnyPublisher<String, Never> = balanceWasUpdatedAt.map {
            BalanceLastUpdatedFormatter().string(from: $0)
        }.eraseToAnyPublisher()

        return Output(
            isFetchingBalance: activityIndicator.asPublisher(),
            balance: latestBalanceOrZero.map { formatter.format(amount: $0, in: .zil, formatThousands: true) }.eraseToAnyPublisher(),
            refreshControlLastUpdatedTitle: refreshControlLastUpdatedTitle
        )
    }
}

extension MainViewModel {
    /// User-event publishers the view-model consumes.
    struct InputFromView {
        /// Fires when the user pulls to refresh.
        let pullToRefreshTrigger: AnyPublisher<Void, Never>
        /// Fires when the user taps Send.
        let sendTrigger: AnyPublisher<Void, Never>
        /// Fires when the user taps Receive.
        let receiveTrigger: AnyPublisher<Void, Never>
    }

    /// Reactive bindings the view installs.
    struct Output {
        /// Drives the pull-to-refresh spinner.
        let isFetchingBalance: AnyPublisher<Bool, Never>
        /// Pre-formatted balance string (ZIL, with thousands separator).
        let balance: AnyPublisher<String, Never>
        /// Localized "Updated N min ago" string for the refresh control.
        let refreshControlLastUpdatedTitle: AnyPublisher<String, Never>
    }
}
