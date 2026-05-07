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
import Foundation
import Zesame

// MARK: - Narrow use cases (split from the old monolithic `TransactionsUseCase`)

/// Reads and writes the locally-cached wallet balance so the UI can show a last-known
/// value before a fresh fetch completes.
public protocol BalanceCacheUseCase {
    /// The most-recent cached `Amount`, or `nil` if no balance has ever been cached.
    var cachedBalance: Amount? { get }

    /// Persists `balance` as the latest cached balance and updates the "last updated"
    /// timestamp to now.
    func cacheBalance(_ balance: Amount)

    /// The timestamp when the cached balance was last written, or `nil` if never.
    var balanceUpdatedAt: Date? { get }

    /// Explicitly overrides the "last updated" timestamp (used when a fetch completes
    /// without changing the balance).
    func balanceWasUpdated(at date: Date)

    /// Clears both the cached balance and its "last updated" timestamp.
    func deleteCachedBalance()
}

/// Fetches the minimum allowed gas price for an outgoing transaction.
public protocol GasPriceUseCase {
    /// Returns the network's minimum gas price as a one-shot publisher.
    func getMinimumGasPrice() -> AnyPublisher<Amount, Swift.Error>
}

/// Fetches a live wallet balance for a given on-chain address.
public protocol FetchBalanceUseCase {
    /// Fetches the live balance and nonce for `address`.
    func getBalance(for address: LegacyAddress) -> AnyPublisher<BalanceResponse, Swift.Error>
}

/// Signs and broadcasts a transaction to the Zilliqa network.
public protocol SendTransactionUseCase {
    /// Signs `payment` with the keystore inside `wallet` (unlocked by
    /// `encryptionPassword`) and broadcasts the transaction, emitting the resulting
    /// `TransactionResponse` once on success.
    func sendTransaction(for payment: Payment, wallet: Wallet, encryptionPassword: String)
        -> AnyPublisher<TransactionResponse, Swift.Error>
}

/// Polls the network for a transaction receipt, confirming inclusion.
public protocol TransactionReceiptUseCase {
    /// Polls the network with the supplied `polling` schedule until the transaction
    /// identified by `txId` reaches consensus, then emits its `TransactionReceipt`.
    func receiptOfTransaction(byId txId: String, polling: Polling)
        -> AnyPublisher<TransactionReceipt, Swift.Error>
}

// MARK: - Composite façade (backward-compatibility)

/// Composite protocol retained for backwards compatibility with existing call sites.
///
/// Prefer the narrow protocols above (`BalanceCacheUseCase`, `GasPriceUseCase`,
/// `FetchBalanceUseCase`, `SendTransactionUseCase`, `TransactionReceiptUseCase`) in
/// new code.
public protocol TransactionsUseCase: BalanceCacheUseCase,
    GasPriceUseCase,
    FetchBalanceUseCase,
    SendTransactionUseCase,
    TransactionReceiptUseCase {}
