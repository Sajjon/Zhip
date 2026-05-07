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

@testable import AppFeature
import Combine
import Factory
import NanoViewControllerDIPrimitives
import XCTest
import Zesame

/// Tests for `DefaultTransactionsUseCase`, which uses constructor DI (not
/// `@Injected`) so tests instantiate it directly with mocked dependencies.
@MainActor
final class DefaultTransactionsUseCaseTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var mockService: MockZilliqaServiceReactive!
    private var preferences: Preferences!
    private var securePersistence: SecurePersistence!
    private var sut: DefaultTransactionsUseCase!

    override func setUp() {
        super.setUp()
        mockService = MockZilliqaServiceReactive()
        preferences = TestStoreFactory.makePreferences()
        securePersistence = TestStoreFactory.makeSecurePersistence()
        sut = DefaultTransactionsUseCase(
            zilliqaService: mockService,
            securePersistence: securePersistence,
            preferences: preferences
        )
    }

    override func tearDown() {
        cancellables.removeAll()
        sut = nil
        preferences = nil
        securePersistence = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - Balance cache

    func test_cachedBalance_returnsNilWhenNoValueStored() {
        XCTAssertNil(sut.cachedBalance)
        XCTAssertNil(sut.balanceUpdatedAt)
    }

    func test_cacheBalance_persistsValueAndStampsUpdatedAt() throws {
        let amount = try Amount(qa: "12345")
        // DateProvider is stubbed by SilenceSideEffects with FixedDateProvider;
        // the use case stamps `balanceUpdatedAt` to whatever `dateProvider.now()`
        // returns, so we assert against the stub's current value.
        let stubbedNow = try XCTUnwrap(
            (Container.shared.dateProvider() as? FixedDateProvider)?.fixedNow
        )

        sut.cacheBalance(amount)

        XCTAssertEqual(sut.cachedBalance?.qaString, "12345")
        XCTAssertEqual(sut.balanceUpdatedAt, stubbedNow)
    }

    func test_balanceWasUpdated_writesTimestampOnly() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        sut.balanceWasUpdated(at: date)

        XCTAssertEqual(sut.balanceUpdatedAt, date)
        XCTAssertNil(sut.cachedBalance)
    }

    func test_deleteCachedBalance_clearsBothValues() throws {
        let amount = try Amount(qa: "9999")
        sut.cacheBalance(amount)

        sut.deleteCachedBalance()

        XCTAssertNil(sut.cachedBalance)
        XCTAssertNil(sut.balanceUpdatedAt)
    }

    func test_cachedBalance_returnsNilWhenStoredValueFailsToParse() {
        preferences.save(value: "not-a-number", for: .cachedBalance)
        XCTAssertNil(sut.cachedBalance)
    }

    // MARK: - On-chain calls

    func test_getMinimumGasPrice_forwardsToServiceAndMapsAmount() throws {
        let json = Data("\"1000000000\"".utf8)
        let response = try JSONDecoder().decode(MinimumGasPriceResponse.self, from: json)
        mockService.minimumGasPriceResult = .success(response)
        var received: Amount?
        let expectation = expectation(description: "value")

        sut.getMinimumGasPrice()
            .sink(receiveCompletion: { _ in }, receiveValue: {
                received = $0
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(mockService.getMinimumGasPriceCallCount, 1)
        XCTAssertEqual(received?.qaString, "1000000000")
    }

    func test_getBalance_forwardsAddressAndReturnsResponse() throws {
        let address = try LegacyAddress(string: "e3090a1309DfAC40352d03dEc6cCD9cAd213e76B")
        let balance = try Amount(qa: "500")
        let nonce = Nonce(7)
        mockService.balanceResult = .success(BalanceResponse(balance: balance, nonce: nonce))
        var received: BalanceResponse?
        let expectation = expectation(description: "value")

        sut.getBalance(for: address)
            .sink(receiveCompletion: { _ in }, receiveValue: {
                received = $0
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(mockService.getBalanceCallCount, 1)
        XCTAssertEqual(mockService.lastBalanceAddress, address)
        XCTAssertEqual(received?.balance.qaString, "500")
    }

    func test_receiptOfTransaction_forwardsTxIdAndReturnsReceipt() throws {
        let receipt = try TransactionReceipt(id: "0xabc", totalGasCost: Amount(qa: "100"))
        mockService.transactionReceiptResult = .success(receipt)
        var received: TransactionReceipt?
        let expectation = expectation(description: "value")

        sut.receiptOfTransaction(byId: "0xabc", polling: .twentyTimesLinearBackoff)
            .sink(receiveCompletion: { _ in }, receiveValue: {
                received = $0
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(mockService.receiptCallCount, 1)
        XCTAssertEqual(mockService.lastReceiptTxId, "0xabc")
        XCTAssertEqual(received?.transactionId, "0xabc")
    }

    // MARK: - sendTransaction

    func test_sendTransaction_chainsNetworkFetchIntoSend() throws {
        let networkJSON = Data("\"1\"".utf8)
        let networkResponse = try JSONDecoder().decode(NetworkResponse.self, from: networkJSON)
        mockService.networkResult = .success(networkResponse)
        let txJSON = Data("{\"TranID\":\"tx-1\",\"Info\":\"sent\"}".utf8)
        let txResponse = try JSONDecoder().decode(TransactionResponse.self, from: txJSON)
        mockService.sendTransactionResult = .success(txResponse)

        let wallet = TestWalletFactory.makeWallet()
        let toAddress = try LegacyAddress(string: "e3090a1309DfAC40352d03dEc6cCD9cAd213e76B")
        let payment = try Payment(
            to: toAddress,
            amount: Amount(zil: 1),
            gasPrice: GasPrice(li: 1_000_000)
        )
        var received: TransactionResponse?
        let expectation = expectation(description: "value")

        sut.sendTransaction(for: payment, wallet: wallet, encryptionPassword: "pw123")
            .sink(receiveCompletion: { _ in }, receiveValue: {
                received = $0
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(mockService.getNetworkCallCount, 1)
        XCTAssertEqual(mockService.sendTransactionCallCount, 1)
        XCTAssertEqual(mockService.lastSendTransactionPassword, "pw123")
        XCTAssertEqual(received?.transactionIdentifier, "tx-1")
    }
}
