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
import UIKit
import Zesame

/// Outcome the Send sub-flow surfaces to its parent (`MainCoordinator`).
enum SendCoordinatorNavigationStep {
    /// Send flow finished. `fetchBalance: true` means a transaction was
    /// successfully signed and broadcast — Main should refetch the balance.
    case finish(fetchBalance: Bool)
}

// MARK: - SendCoordinator

/// Coordinator owning the four-step send-transaction sub-flow:
///
/// 1. `PrepareTransaction` — enter recipient/amount/gas (or scan QR).
/// 2. `ReviewTransactionBeforeSigning` — confirm the prepared payment.
/// 3. `SignTransaction` — re-enter password, sign + broadcast.
/// 4. `PollTransactionStatus` — wait for the network to confirm the receipt.
///
/// QR-scan output and inbound deep links converge into a single `transactionIntent`
/// publisher consumed by step 1.
final class SendCoordinator: BaseCoordinator<SendCoordinatorNavigationStep> {
    /// URL opener — injected so tests can register a no-op and we keep the
    /// "view tx in browser" call behind the same DI surface as everything else.
    @Injected(\.urlOpener) private var urlOpener: UrlOpener

    /// Merged stream of "incoming pre-filled payments" — either a deep link
    /// (passed in by the parent) or a freshly-scanned QR code.
    private let transactionIntent: AnyPublisher<TransactionIntent, Never>
    /// Subject used to push QR-scanned intents into `transactionIntent`.
    private let scannedQRTransactionSubject = PassthroughSubject<TransactionIntent, Never>()

    /// Captures the deep-link source and merges it with the QR subject.
    init(
        navigationController: UINavigationController,
        deeplinkedTransaction: AnyPublisher<TransactionIntent, Never>
    ) {
        transactionIntent = deeplinkedTransaction.merge(with: scannedQRTransactionSubject.replaceErrorWithEmpty()).eraseToAnyPublisher()
        super.init(navigationController: navigationController)
    }

    /// Begins at step 1.
    override func start(didStart _: Completion? = nil) {
        toFirst()
    }
}

// MARK: - Navigate

private extension SendCoordinator {
    /// Convenience wrapper for the entry point.
    func toFirst() {
        toPrepareTransaction()
    }

    /// Step 1 — push the prepare screen. Filters incoming intents to only
    /// surface them when prepare is the topmost scene (so a QR-scan return
    /// doesn't accidentally pre-fill while review/sign is up).
    /// `[weak self]` because `transactionIntent` includes the parent's
    /// deep-link publisher, which can outlive this coordinator.
    func toPrepareTransaction() {
        let viewModel = PrepareTransactionViewModel(
            scannedOrDeeplinkedTransaction: transactionIntent.filter { [weak self] _ in
                guard let self else { return false }
                let prepareTransactionIsCurrentScene = self.navigationController.viewControllers
                    .isEmpty || self.isTopmost(scene: PrepareTransaction.self)
                guard prepareTransactionIsCurrentScene else {
                    // Prevented deeplinked transaction since it is not the active scene
                    return false
                }
                return true
            }.eraseToAnyPublisher()
        )

        push(scene: PrepareTransaction.self, viewModel: viewModel) { [weak self] userIntendsTo in
            guard let self else { return }
            switch userIntendsTo {
            case .cancel: self.finish()
            case .scanQRCode: self.toScanQRCode()
            case let .reviewPayment(payment): self.toReviewPaymentBeforeSigning(payment)
            }
        }
    }

    /// Side-trip from prepare — modally presents the QR scanner. On success,
    /// dismiss *first* then push the scanned intent through the subject so the
    /// prepare screen receives it after it's regained focus.
    func toScanQRCode() {
        modallyPresent(
            scene: ScanQRCode.self,
            viewModel: ScanQRCodeViewModel()
        ) { [weak self] userDid, dismissScene in
            switch userDid {
            case let .scanQRContainingTransaction(transaction):
                dismissScene(true) {
                    self?.scannedQRTransactionSubject.send(transaction)
                }
            case .cancel:
                dismissScene(true, nil)
            }
        }
    }

    /// Step 2 — review the prepared payment. Acceptance advances to signing.
    func toReviewPaymentBeforeSigning(_ payment: Payment) {
        let viewModel = ReviewTransactionBeforeSigningViewModel(
            paymentToReview: payment
        )

        push(scene: ReviewTransactionBeforeSigning.self, viewModel: viewModel) { [weak self] userDid in
            switch userDid {
            case let .acceptPaymentProceedWithSigning(reviewedPayment):
                self?.toSignPayment(reviewedPayment)
            }
        }
    }

    /// Step 3 — re-enter password, sign, broadcast. On success, advance to
    /// status polling. If the wallet has been removed under us
    /// (`.walletUnavailable`), bail out of the whole Send flow rather than
    /// crashing inside the signing screen.
    func toSignPayment(_ payment: Payment) {
        let viewModel = SignTransactionViewModel(paymentToSign: payment)

        push(scene: SignTransaction.self, viewModel: viewModel) { [weak self] userDid in
            guard let self else { return }
            switch userDid {
            case let .sign(transactionResponse):
                self.toWaitForReceiptForTransactionWith(id: transactionResponse.transactionIdentifier)
            case .walletUnavailable:
                self.finish()
            }
        }
    }

    /// Step 4 — poll the network for the transaction receipt. `.dismiss`
    /// (user saw "confirmed") triggers a balance refetch on Main.
    func toWaitForReceiptForTransactionWith(id transactionId: String) {
        let viewModel = PollTransactionStatusViewModel(transactionId: transactionId)

        push(scene: PollTransactionStatus.self, viewModel: viewModel) { [weak self] userDid in
            guard let self else { return }
            switch userDid {
            case .skip, .waitUntilTimeout: self.finish()
            case .dismiss: self.finish(triggerBalanceFetching: true)
            case let .viewTransactionDetailsInBrowser(txId): self.openInBrowserDetailsForTransaction(id: txId)
            }
        }
    }

    /// Opens the transaction details on viewblock.io via the injected
    /// `UrlOpener`. Routed through DI so tests can record the call instead of
    /// triggering a real workspace round-trip in the simulator.
    func openInBrowserDetailsForTransaction(id transactionId: String) {
        let baseURL = "https://viewblock.io/zilliqa/"
        let urlString = "tx/\(transactionId)"
        guard let url = URL(string: urlString, relativeTo: URL(string: baseURL)) else {
            return
        }
        urlOpener.open(url)
    }

    /// Bubble `.finish` to the parent. `triggerBalanceFetching: true` signals
    /// that a transaction was broadcast and Main should refresh.
    func finish(triggerBalanceFetching: Bool = false) {
        navigator.next(.finish(fetchBalance: triggerBalanceFetching))
    }
}
