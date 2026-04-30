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
import Zesame
@testable import AppFeature

/// Hand-written mock conforming to every narrow transactions use-case protocol for
/// ViewModel tests. Async methods read from seedable `*Result` properties; cache
/// methods mutate in-memory storage and bump call counters.
final class MockTransactionsUseCase: TransactionsUseCase {
    // MARK: - Cache state

    var cachedBalance: Amount?
    var balanceUpdatedAt: Date?

    private(set) var cacheBalanceCallCount = 0
    private(set) var balanceWasUpdatedAtCallCount = 0
    private(set) var deleteCachedBalanceCallCount = 0

    func cacheBalance(_ balance: Amount) {
        cacheBalanceCallCount += 1
        cachedBalance = balance
        balanceUpdatedAt = Date()
    }

    func balanceWasUpdated(at date: Date) {
        balanceWasUpdatedAtCallCount += 1
        balanceUpdatedAt = date
    }

    func deleteCachedBalance() {
        deleteCachedBalanceCallCount += 1
        cachedBalance = nil
        balanceUpdatedAt = nil
    }

    // MARK: - Network state

    var minimumGasPriceResult: Result<Amount, Swift.Error>
    var balanceResult: Result<BalanceResponse, Swift.Error>
    var sendTransactionResult: Result<TransactionResponse, Swift.Error>?
    var receiptResult: Result<TransactionReceipt, Swift.Error>?

    private(set) var getMinimumGasPriceCallCount = 0
    private(set) var getBalanceCallCount = 0
    private(set) var sendTransactionCallCount = 0
    private(set) var receiptOfTransactionCallCount = 0
    private(set) var lastSendTransactionPayment: Payment?

    init(
        minimumGasPriceResult: Result<Amount, Swift.Error> = .success((try? Amount(zil: 1)) ?? 0),
        balanceResult: Result<BalanceResponse, Swift.Error> = .success(
            BalanceResponse(balance: (try? Amount(zil: 0)) ?? 0, nonce: 0)
        )
    ) {
        self.minimumGasPriceResult = minimumGasPriceResult
        self.balanceResult = balanceResult
    }

    func getMinimumGasPrice() -> AnyPublisher<Amount, Swift.Error> {
        getMinimumGasPriceCallCount += 1
        return publisher(for: minimumGasPriceResult)
    }

    func getBalance(for _: LegacyAddress) -> AnyPublisher<BalanceResponse, Swift.Error> {
        getBalanceCallCount += 1
        return publisher(for: balanceResult)
    }

    func sendTransaction(
        for payment: Payment,
        wallet _: AppFeature.Wallet,
        encryptionPassword _: String
    ) -> AnyPublisher<TransactionResponse, Swift.Error> {
        sendTransactionCallCount += 1
        lastSendTransactionPayment = payment
        if let result = sendTransactionResult {
            return publisher(for: result)
        }
        return Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    func receiptOfTransaction(
        byId _: String,
        polling _: Polling
    ) -> AnyPublisher<TransactionReceipt, Swift.Error> {
        receiptOfTransactionCallCount += 1
        if let result = receiptResult {
            return publisher(for: result)
        }
        return Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    // MARK: - Helpers

    private func publisher<Output>(for result: Result<Output, Swift.Error>) -> AnyPublisher<Output, Swift.Error> {
        switch result {
        case let .success(value):
            Just(value).setFailureType(to: Swift.Error.self).eraseToAnyPublisher()
        case let .failure(error):
            Fail(error: error).eraseToAnyPublisher()
        }
    }
}
