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
@testable import Zhip

/// Tests for `MainViewModel`.
///
/// Covers the three navigation buttons (settings, send, receive), the
/// `getMinimumGasPrice` warm-up call on transform, and the balance-fetch /
/// cache-write loop driven by the `updateBalanceTrigger` and
/// `pullToRefreshTrigger` inputs.
final class MainViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var updateBalanceTrigger: PassthroughSubject<Void, Never>!
    private var pullToRefresh: PassthroughSubject<Void, Never>!
    private var sendTrigger: PassthroughSubject<Void, Never>!
    private var receiveTrigger: PassthroughSubject<Void, Never>!
    private var fakeController: FakeInputFromController!
    private var mockTransactions: MockTransactionsUseCase!
    private var mockWallet: MockWalletUseCase!

    override func setUp() {
        super.setUp()
        updateBalanceTrigger = PassthroughSubject<Void, Never>()
        pullToRefresh = PassthroughSubject<Void, Never>()
        sendTrigger = PassthroughSubject<Void, Never>()
        receiveTrigger = PassthroughSubject<Void, Never>()
        fakeController = FakeInputFromController()
        mockTransactions = MockTransactionsUseCase()
        mockWallet = MockWalletUseCase()
        mockWallet.storedWallet = TestWalletFactory.makeWallet()
        Container.shared.transactionsUseCase.register { [unowned self] in mockTransactions }
        Container.shared.walletStorageUseCase.register { [unowned self] in mockWallet }
    }

    override func tearDown() {
        cancellables.removeAll()
        Container.shared.manager.reset()
        mockWallet = nil
        mockTransactions = nil
        fakeController = nil
        receiveTrigger = nil
        sendTrigger = nil
        pullToRefresh = nil
        updateBalanceTrigger = nil
        super.tearDown()
    }

    func test_rightBarButton_emitsGoToSettings() {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var observed: MainUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        fakeController.rightBarButtonTriggerSubject.send(())

        XCTAssertEqual(observed, .goToSettings)
    }

    func test_sendTrigger_emitsSend() {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var observed: MainUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        sendTrigger.send(())

        XCTAssertEqual(observed, .send)
    }

    func test_receiveTrigger_emitsReceive() {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var observed: MainUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        receiveTrigger.send(())

        XCTAssertEqual(observed, .receive)
    }

    func test_transform_callsGetMinimumGasPrice() {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())

        XCTAssertEqual(mockTransactions.getMinimumGasPriceCallCount, 1)
    }

    func test_balance_emitsFormattedString() {
        let sut = makeSUT()
        let output = sut.transform(input: makeInput())
        var balance: String?
        output.balance.sink { balance = $0 }.store(in: &cancellables)

        XCTAssertNotNil(balance)
        XCTAssertFalse((balance ?? "").isEmpty)
    }

    func test_pullToRefresh_callsGetBalance() {
        let sut = makeSUT()
        let output = sut.transform(input: makeInput())
        // Subscribe so the latestBalanceAndNonce chain is active
        output.balance.sink { _ in }.store(in: &cancellables)
        let baselineFetches = mockTransactions.getBalanceCallCount

        pullToRefresh.send(())

        XCTAssertGreaterThan(mockTransactions.getBalanceCallCount, baselineFetches)
    }

    private func makeSUT() -> MainViewModel {
        MainViewModel(updateBalanceTrigger: updateBalanceTrigger.eraseToAnyPublisher())
    }

    private func makeInput() -> MainViewModel.Input {
        MainViewModel.Input(
            fromView: .init(
                pullToRefreshTrigger: pullToRefresh.eraseToAnyPublisher(),
                sendTrigger: sendTrigger.eraseToAnyPublisher(),
                receiveTrigger: receiveTrigger.eraseToAnyPublisher()
            ),
            fromController: fakeController.makeInput()
        )
    }
}
