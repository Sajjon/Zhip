// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import Factory
import Foundation
import NanoViewControllerCombine
import NanoViewControllerDIPrimitives
import Zesame

/// Default implementation of the composite `TransactionsUseCase` and all five
/// narrow protocols it composes.
///
/// Pure balance-cache operations read/write `preferences` only; live on-chain
/// operations (balance fetch, transaction send, receipt poll) delegate to
/// `zilliqaService`.
public final class DefaultTransactionsUseCase {
    /// Reactive Zesame façade used for all on-chain work.
    private let zilliqaService: ZilliqaServiceReactive

    /// Secret key-value store. Currently unused by the transactions use case but
    /// retained so `SecurePersisting` conformance can be added if needed.
    let securePersistence: SecurePersistence

    /// Non-secret key-value store (cached balance, last-updated timestamp).
    let preferences: Preferences

    /// "Now" oracle used when stamping a freshly-cached balance's last-updated
    /// timestamp. Resolved via Factory so tests register a deterministic stand-in.
    @Injected(\.dateProvider) private var dateProvider: DateProvider

    /// Designated initializer. Inject stand-ins in tests to make the use case
    /// fully deterministic.
    init(zilliqaService: ZilliqaServiceReactive, securePersistence: SecurePersistence, preferences: Preferences) {
        self.zilliqaService = zilliqaService
        self.securePersistence = securePersistence
        self.preferences = preferences
    }
}

extension DefaultTransactionsUseCase: TransactionsUseCase {
    /// The most-recent cached `Amount`, decoded from its persisted Qa string.
    /// Returns `nil` if no balance has ever been cached or if the stored value
    /// fails to parse.
    public var cachedBalance: Amount? {
        guard let qa: String = preferences.loadValue(for: .cachedBalance) else { return nil }
        return try? Amount(qa: qa)
    }

    /// The timestamp of the most recent cached balance, or `nil` if the cache is
    /// empty.
    public var balanceUpdatedAt: Date? {
        preferences.loadValue(for: .balanceWasUpdatedAt)
    }

    /// Explicitly overrides the "last updated" timestamp — used when a fetch
    /// completes with no change in balance but we still want to refresh the UI's
    /// "last updated" label.
    public func balanceWasUpdated(at date: Date) {
        preferences.save(value: date, for: .balanceWasUpdatedAt)
    }

    /// Clears both the cached balance and its last-updated timestamp.
    public func deleteCachedBalance() {
        preferences.deleteValue(for: .cachedBalance)
        preferences.deleteValue(for: .balanceWasUpdatedAt)
    }

    /// Persists `balance` as the latest cached balance and stamps "last updated"
    /// to now.
    public func cacheBalance(_ balance: Amount) {
        preferences.save(value: balance.qaString, for: .cachedBalance)
        balanceWasUpdated(at: dateProvider.now())
    }

    /// Returns the network's minimum gas price as a one-shot publisher, also
    /// updating Zesame's internal cached minimum.
    public func getMinimumGasPrice() -> AnyPublisher<Amount, Swift.Error> {
        zilliqaService.getMinimumGasPrice(alsoUpdateLocallyCachedMinimum: true)
            .map(\.amount)
            .mapError { $0 as Swift.Error }
            // Hop to main — see DefaultCreateWalletUseCase for full rationale.
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Fetches the live balance and nonce for `address`.
    public func getBalance(for address: LegacyAddress) -> AnyPublisher<BalanceResponse, Swift.Error> {
        zilliqaService.getBalance(for: address)
            .mapError { $0 as Swift.Error }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Signs `payment` with the keystore inside `wallet` (unlocked by
    /// `encryptionPassword`) and broadcasts the transaction on the current
    /// network, emitting the resulting `TransactionResponse` once on success.
    public func sendTransaction(for payment: Payment, wallet: Wallet, encryptionPassword: String)
        -> AnyPublisher<TransactionResponse, Swift.Error>
    {
        zilliqaService.getNetworkFromAPI()
            .mapError { $0 as Swift.Error }
            .flatMapLatest { [weak self] networkResponse -> AnyPublisher<TransactionResponse, Swift.Error> in
                guard let self else { return Empty().eraseToAnyPublisher() }
                return zilliqaService.sendTransaction(
                    for: payment,
                    keystore: wallet.keystore,
                    password: encryptionPassword,
                    network: networkResponse.network
                )
                .mapError { $0 as Swift.Error }
                .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// Polls the network with the supplied `polling` schedule until the transaction
    /// identified by `txId` reaches consensus, then emits its `TransactionReceipt`.
    public func receiptOfTransaction(
        byId txId: String,
        polling: Polling
    ) -> AnyPublisher<TransactionReceipt, Swift.Error> {
        zilliqaService.hasNetworkReachedConsensusYetForTransactionWith(id: txId, polling: polling)
            .mapError { $0 as Swift.Error }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
