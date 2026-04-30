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
import XCTest
import Zesame
import SingleLineControllerController
@testable import AppFeature

/// Tests for `PollTransactionStatusViewModel`.
///
/// Covers copy-to-pasteboard with toast, the receipt-arrival branch (skip → done
/// title and `.dismiss` action), the no-receipt branch (`.skip` action), and the
/// see-tx-details branch that emits `.viewTransactionDetailsInBrowser`.
final class PollTransactionStatusViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var copyTrigger: PassthroughSubject<Void, Never>!
    private var skipTrigger: PassthroughSubject<Void, Never>!
    private var seeTxDetails: PassthroughSubject<Void, Never>!
    private var fakeController: FakeInputFromController!
    private var mockTransactions: MockTransactionsUseCase!
    private var mockPasteboard: MockPasteboard!
    private let txId = "tx-id-12345"

    override func setUp() {
        super.setUp()
        copyTrigger = PassthroughSubject<Void, Never>()
        skipTrigger = PassthroughSubject<Void, Never>()
        seeTxDetails = PassthroughSubject<Void, Never>()
        fakeController = FakeInputFromController()
        mockTransactions = MockTransactionsUseCase()
        Container.shared.transactionReceiptUseCase.register { [unowned self] in mockTransactions }
        mockPasteboard = MockPasteboard()
        Container.shared.pasteboard.register { [unowned self] in mockPasteboard }
    }

    override func tearDown() {
        cancellables.removeAll()
        Container.shared.manager.reset()
        mockPasteboard = nil
        mockTransactions = nil
        fakeController = nil
        seeTxDetails = nil
        skipTrigger = nil
        copyTrigger = nil
        super.tearDown()
    }

    func test_copyTransactionId_writesIdToPasteboardAndSendsToast() {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var toasts: [Toast] = []
        fakeController.toastSubject.sink { toasts.append($0) }.store(in: &cancellables)

        copyTrigger.send(())

        XCTAssertEqual(toasts.count, 1)
        XCTAssertEqual(mockPasteboard.copiedString, txId)
    }

    func test_skipBeforeReceipt_emitsSkip() {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var observed: PollTransactionStatusUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        skipTrigger.send(())

        guard case .skip = observed else {
            return XCTFail("Expected .skip, got \(String(describing: observed))")
        }
    }

    func test_skipAfterReceipt_emitsDismiss() {
        let receipt = TransactionReceipt(id: txId, totalGasCost: 0)
        mockTransactions.receiptResult = .success(receipt)
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var observed: PollTransactionStatusUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        skipTrigger.send(())

        guard case .dismiss = observed else {
            return XCTFail("Expected .dismiss, got \(String(describing: observed))")
        }
    }

    func test_seeTxDetails_emitsViewTransactionDetailsInBrowser() {
        let receipt = TransactionReceipt(id: txId, totalGasCost: 0)
        mockTransactions.receiptResult = .success(receipt)
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var observed: PollTransactionStatusUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        seeTxDetails.send(())

        guard case let .viewTransactionDetailsInBrowser(id) = observed else {
            return XCTFail("Expected .viewTransactionDetailsInBrowser, got \(String(describing: observed))")
        }
        XCTAssertEqual(id, txId)
    }

    func test_skipButtonTitle_changesAfterReceipt() {
        let receipt = TransactionReceipt(id: txId, totalGasCost: 0)
        mockTransactions.receiptResult = .success(receipt)
        let sut = makeSUT()
        let output = sut.transform(input: makeInput())
        var titles: [String] = []
        output.skipWaitingOrDoneButtonTitle.sink { titles.append($0) }.store(in: &cancellables)

        XCTAssertGreaterThanOrEqual(titles.count, 2)
        XCTAssertNotEqual(titles.first, titles.last)
    }

    private func makeSUT() -> PollTransactionStatusViewModel {
        PollTransactionStatusViewModel(transactionId: txId)
    }

    private func makeInput() -> PollTransactionStatusViewModel.Input {
        PollTransactionStatusViewModel.Input(
            fromView: .init(
                copyTransactionIdTrigger: copyTrigger.eraseToAnyPublisher(),
                skipWaitingOrDoneTrigger: skipTrigger.eraseToAnyPublisher(),
                seeTxDetails: seeTxDetails.eraseToAnyPublisher()
            ),
            fromController: fakeController.makeInput()
        )
    }
}
