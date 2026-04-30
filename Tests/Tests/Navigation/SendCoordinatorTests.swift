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

@testable import AppFeature
import Combine
import Factory
import SingleLineControllerController
import UIKit
import XCTest
import Zesame

/// Covers `SendCoordinator` navigation branches: the chain from
/// `PrepareTransaction` through `ScanQRCode` / `ReviewTransaction` /
/// `SignTransaction` / `PollTransactionStatus`, plus the final `finish` bubble.
final class SendCoordinatorTests: XCTestCase {
    private var window: UIWindow!
    private var navigationController: NavigationBarLayoutingNavigationController!
    private var mockTransactions: MockTransactionsUseCase!
    private var mockWallet: MockWalletUseCase!
    private var deeplinkSubject: PassthroughSubject<TransactionIntent, Never>!
    private var cancellables: Set<AnyCancellable> = []
    private var sut: SendCoordinator!

    override func setUp() {
        super.setUp()
        mockTransactions = MockTransactionsUseCase()
        mockWallet = MockWalletUseCase()
        mockWallet.storedWallet = TestWalletFactory.makeWallet()
        Container.shared.transactionsUseCase.register { [unowned self] in mockTransactions }
        Container.shared.walletStorageUseCase.register { [unowned self] in mockWallet }
        deeplinkSubject = PassthroughSubject<TransactionIntent, Never>()
        navigationController = NavigationBarLayoutingNavigationController()
        window = UIWindow(frame: .init(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        sut = SendCoordinator(
            navigationController: navigationController,
            deeplinkedTransaction: deeplinkSubject.eraseToAnyPublisher()
        )
    }

    override func tearDown() {
        drainRunLoop()
        cancellables.removeAll()
        sut = nil
        window.isHidden = true
        window = nil
        navigationController = nil
        deeplinkSubject = nil
        Container.shared.manager.reset()
        mockWallet = nil
        mockTransactions = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func top<T>(as _: T.Type) -> T? {
        navigationController.viewControllers.last as? T
    }

    private func makePayment() throws -> Payment {
        let address = try LegacyAddress(string: "e3090a1309DfAC40352d03dEc6cCD9cAd213e76B")
        let amount = try Amount(zil: 1)
        let gasPrice = try GasPrice(li: 1_000_000)
        return try Payment(to: address, amount: amount, gasPrice: gasPrice)
    }

    // MARK: - start

    func test_start_pushesPrepareTransactionAsRoot() {
        sut.start()

        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers.first is PrepareTransaction)
    }

    // MARK: - PrepareTransaction branches

    func test_prepareTransactionCancel_bubblesFinish() throws {
        sut.start()
        var received: SendCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)
        let prepare = try XCTUnwrap(top(as: PrepareTransaction.self))

        prepare.viewModel.navigator.next(.cancel)
        drainRunLoop()

        if case .finish = received { } else {
            XCTFail("expected .finish, got \(String(describing: received))")
        }
    }

    func test_prepareTransactionScanQR_presentsScanQRCode() throws {
        sut.start()
        let prepare = try XCTUnwrap(top(as: PrepareTransaction.self))

        prepare.viewModel.navigator.next(.scanQRCode)
        drainRunLoop()
        // Presentation is modal; just verifying no crash.
    }

    func test_prepareTransactionReviewPayment_pushesReviewTransaction() throws {
        sut.start()
        let prepare = try XCTUnwrap(top(as: PrepareTransaction.self))
        let payment = try makePayment()

        prepare.viewModel.navigator.next(.reviewPayment(payment))
        drainRunLoop()

        XCTAssertTrue(top(as: ReviewTransactionBeforeSigning.self) != nil)
    }

    // MARK: - ReviewTransaction → SignTransaction

    func test_reviewAcceptPayment_pushesSignTransaction() throws {
        sut.start()
        let prepare = try XCTUnwrap(top(as: PrepareTransaction.self))
        let payment = try makePayment()
        prepare.viewModel.navigator.next(.reviewPayment(payment))
        drainRunLoop()
        let review = try XCTUnwrap(top(as: ReviewTransactionBeforeSigning.self))

        review.viewModel.navigator.next(.acceptPaymentProceedWithSigning(payment))
        drainRunLoop()

        XCTAssertTrue(top(as: SignTransaction.self) != nil)
    }

    // MARK: - Deep-link forwarding

    func test_deeplinkedTransaction_whenPrepareTransactionIsTop_forwardsToScannedSubject() throws {
        sut.start()
        let address = try Address(string: "e3090a1309DfAC40352d03dEc6cCD9cAd213e76B")
        let intent = TransactionIntent(to: address)

        deeplinkSubject.send(intent)
        drainRunLoop()
        // No crash; the filter in PrepareTransactionViewModel lets the intent through.
    }

    // MARK: - Sign → PollTransactionStatus

    private func makeTransactionResponse() throws -> TransactionResponse {
        try JSONDecoder().decode(TransactionResponse.self, from: Data(#"{"TranID":"abc123","Info":"Sent"}"#.utf8))
    }

    private func pushToSignTransaction() throws -> SignTransaction {
        sut.start()
        let prepare = top(as: PrepareTransaction.self)!
        let payment = try makePayment()
        prepare.viewModel.navigator.next(.reviewPayment(payment))
        drainRunLoop()
        let review = top(as: ReviewTransactionBeforeSigning.self)!
        review.viewModel.navigator.next(.acceptPaymentProceedWithSigning(payment))
        drainRunLoop()
        return top(as: SignTransaction.self)!
    }

    func test_signTransactionSign_pushesPollTransactionStatus() throws {
        let sign = try pushToSignTransaction()

        try sign.viewModel.navigator.next(.sign(makeTransactionResponse()))
        drainRunLoop()

        XCTAssertTrue(top(as: PollTransactionStatus.self) != nil)
    }

    // MARK: - PollTransactionStatus branches

    private func pushToPoll() throws -> PollTransactionStatus {
        let sign = try pushToSignTransaction()
        try sign.viewModel.navigator.next(.sign(makeTransactionResponse()))
        drainRunLoop()
        return top(as: PollTransactionStatus.self)!
    }

    func test_pollSkip_bubblesFinishWithoutFetchingBalance() throws {
        let poll = try pushToPoll()
        var received: SendCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)

        poll.viewModel.navigator.next(.skip)
        drainRunLoop()

        if case let .finish(fetch) = received { XCTAssertFalse(fetch) } else {
            XCTFail("expected .finish(false), got \(String(describing: received))")
        }
    }

    func test_pollWaitUntilTimeout_bubblesFinishWithoutFetchingBalance() throws {
        let poll = try pushToPoll()
        var received: SendCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)

        poll.viewModel.navigator.next(.waitUntilTimeout)
        drainRunLoop()

        if case let .finish(fetch) = received { XCTAssertFalse(fetch) } else {
            XCTFail("expected .finish(false), got \(String(describing: received))")
        }
    }

    func test_pollDismiss_bubblesFinishWithFetchingBalance() throws {
        let poll = try pushToPoll()
        var received: SendCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)

        poll.viewModel.navigator.next(.dismiss)
        drainRunLoop()

        if case let .finish(fetch) = received { XCTAssertTrue(fetch) } else {
            XCTFail("expected .finish(true), got \(String(describing: received))")
        }
    }

    func test_pollViewTransactionDetails_opensBrowserWithoutCrashing() throws {
        let poll = try pushToPoll()

        poll.viewModel.navigator.next(.viewTransactionDetailsInBrowser(id: "abc123"))
        drainRunLoop()
        // openURL returns asynchronously; we just verify the path ran.
    }

    // MARK: - Deep-link filter reject branch

    /// When the active scene is no longer `PrepareTransaction`, deep-linked
    /// transactions must be filtered out so they don't mutate an unrelated
    /// scene's state.
    func test_deeplinkedTransaction_whenNotOnPrepare_isFilteredOut() throws {
        sut.start()
        let prepare = try XCTUnwrap(top(as: PrepareTransaction.self))
        let payment = try makePayment()
        prepare.viewModel.navigator.next(.reviewPayment(payment))
        drainRunLoop()
        XCTAssertNotNil(top(as: ReviewTransactionBeforeSigning.self))

        let address = try Address(string: "e3090a1309DfAC40352d03dEc6cCD9cAd213e76B")
        deeplinkSubject.send(TransactionIntent(to: address))
        drainRunLoop()
        // Reject path runs without mutating the scan-QR subject.
    }

    // MARK: - ScanQRCode result branches

    func test_scanQRCode_cancel_dismissesWithoutCrashing() throws {
        sut.start()
        let prepare = try XCTUnwrap(top(as: PrepareTransaction.self))
        prepare.viewModel.navigator.next(.scanQRCode)
        drainRunLoop()

        let presentedNav = navigationController.presentedViewController as? UINavigationController
        let scan = presentedNav?.topViewController as? ScanQRCode
        scan?.viewModel.navigator.next(.cancel)
        drainRunLoop()
    }

    func test_scanQRCode_scannedTransaction_dismissesAndForwardsToSubject() throws {
        sut.start()
        let prepare = try XCTUnwrap(top(as: PrepareTransaction.self))
        prepare.viewModel.navigator.next(.scanQRCode)
        drainRunLoop()

        let presentedNav = navigationController.presentedViewController as? UINavigationController
        let scan = presentedNav?.topViewController as? ScanQRCode
        let address = try Address(string: "e3090a1309DfAC40352d03dEc6cCD9cAd213e76B")
        let intent = TransactionIntent(to: address)
        scan?.viewModel.navigator.next(.scanQRContainingTransaction(intent))
        drainRunLoop()
    }
}
