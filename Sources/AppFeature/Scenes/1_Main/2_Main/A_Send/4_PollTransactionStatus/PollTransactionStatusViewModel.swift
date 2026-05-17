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
import Foundation
import NanoViewControllerCombine
import NanoViewControllerController
import NanoViewControllerCore
import NanoViewControllerDIPrimitives
import UIKit
import Zesame

// MARK: - User action and navigation steps

/// Outcomes of step 4 of Send.
public enum PollTransactionStatusUserAction: Sendable {
    /// User tapped Skip — close before the receipt resolves.
    case skip
    /// Receipt resolved (or user tapped done) — close + trigger balance refetch.
    case dismiss
    /// User tapped "View on viewblock.io" — coordinator opens the URL externally.
    case viewTransactionDetailsInBrowser(id: String)
    /// Polling timed out without a receipt — close anyway.
    case waitUntilTimeout
}

// MARK: - PollTransactionStatusViewModel

/// View model for step 4 of Send. Polls the network for the transaction receipt
/// (linear backoff, 20 attempts), routes user actions (skip/copy/view details),
/// and surfaces a loading-indicator while the poll is in flight.
public final class PollTransactionStatusViewModel: BaseViewModel<
    PollTransactionStatusUserAction,
    PollTransactionStatusViewModel.InputFromView,
    PollTransactionStatusViewModel.Publishers
> {
    /// Receipt-polling use case.
    @Injected(\.transactionReceiptUseCase) private var transactionReceiptUseCase: TransactionReceiptUseCase
    /// Pasteboard wrapper for the copy-tx-id button.
    @Injected(\.pasteboard) private var pasteboard: Pasteboard

    /// The transaction identifier returned by the broadcast call in step 3.
    private let transactionId: String

    /// Captures the transaction id to poll.
    init(transactionId: String) {
        self.transactionId = transactionId
    }

    /// Wires the polling pipeline, the three user actions (skip/copy/view), and
    /// the activity-indicator-driven button states.
    override public func transform(input: Input) -> Output<Publishers, NavigationStep> {
        func userDid(_ userAction: NavigationStep) {
            navigator.next(userAction)
        }

        let activityTracker = ActivityIndicator()

        let receipt = transactionReceiptUseCase.receiptOfTransaction(
            byId: transactionId,
            polling: .twentyTimesLinearBackoff
        )
        .trackActivity(activityTracker)
        .handleEvents(receiveCompletion: { completion in
            if case let .failure(error) = completion,
               let zError = error as? Zesame.Error,
               case .api(.timeout) = zError
            {
                userDid(.waitUntilTimeout)
            }
        })

        let hasReceivedReceipt: AnyPublisher<Bool, Never> = receipt.mapToVoid().replaceErrorWithEmpty().map { true }
            .prepend(false).eraseToAnyPublisher()

        // MARK: Navigate

        [
            input.fromView.copyTransactionIdTrigger
                .sink { [weak self, pasteboard] in
                    guard let self else { return }
                    // pasteboard.copy + Toast init are @MainActor — the
                    // Combine sink closure is @Sendable so we hop explicitly.
                    mainActorOnly {
                        pasteboard.copy(self.transactionId)
                        input.fromController.toastSubject
                            .send(Toast(String(localized: .PollTransaction.copiedTransactionId)))
                    }
                },

            input.fromView.skipWaitingOrDoneTrigger.withLatestFrom(hasReceivedReceipt) { $1 }
                .sink { hasReceivedReceipt in
                    let action: NavigationStep = hasReceivedReceipt ? .dismiss : .skip
                    userDid(action)

                },

            input.fromView.seeTxDetails.withLatestFrom(receipt.replaceErrorWithEmpty()) {
                $1
            }.sink { userDid(.viewTransactionDetailsInBrowser(id: $0.transactionId)) },
        ].forEach { $0.store(in: &cancellables) }

        // MARK: Return output

        return Output(
            publishers: Publishers(
                skipWaitingOrDoneButtonTitle: hasReceivedReceipt
                    .map { $0 ? String(localized: .PollTransaction.done) : String(localized: .PollTransaction.skipWaiting) }
                    .eraseToAnyPublisher(),
                isSeeTxDetailsEnabled: hasReceivedReceipt,
                isSeeTxDetailsButtonLoading: activityTracker.asPublisher()
            ),
            navigation: navigator.navigation
        )
    }
}

public extension PollTransactionStatusViewModel {
    struct InputFromView {
        let copyTransactionIdTrigger: AnyPublisher<Void, Never>
        let skipWaitingOrDoneTrigger: AnyPublisher<Void, Never>
        let seeTxDetails: AnyPublisher<Void, Never>
    }

    struct Publishers {
        let skipWaitingOrDoneButtonTitle: AnyPublisher<String, Never>
        let isSeeTxDetailsEnabled: AnyPublisher<Bool, Never>
        let isSeeTxDetailsButtonLoading: AnyPublisher<Bool, Never>
    }
}
