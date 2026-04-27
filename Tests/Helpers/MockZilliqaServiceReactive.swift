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

/// Seedable mock for `ZilliqaServiceReactive` used by `Default*UseCase` tests.
/// Each method returns the corresponding `*Result` property once, wrapped in a
/// publisher. Call counters are exposed for assertions.
final class MockZilliqaServiceReactive: ZilliqaServiceReactive {
    var createNewWalletResult: Result<Zesame.Wallet, Zesame.Error>?
    var restoreWalletResult: Result<Zesame.Wallet, Zesame.Error>?
    var verifyEncryptionPasswordResult: Result<Bool, Zesame.Error>?
    var extractKeyPairResult: Result<KeyPair, Zesame.Error>?
    var minimumGasPriceResult: Result<MinimumGasPriceResponse, Zesame.Error>?
    var balanceResult: Result<BalanceResponse, Zesame.Error>?
    var networkResult: Result<NetworkResponse, Zesame.Error>?
    var sendTransactionResult: Result<TransactionResponse, Zesame.Error>?
    var transactionReceiptResult: Result<TransactionReceipt, Zesame.Error>?

    private(set) var createNewWalletCallCount = 0
    private(set) var restoreWalletCallCount = 0
    private(set) var verifyEncryptionPasswordCallCount = 0
    private(set) var extractKeyPairCallCount = 0
    private(set) var getNetworkCallCount = 0
    private(set) var getBalanceCallCount = 0
    private(set) var getMinimumGasPriceCallCount = 0
    private(set) var sendTransactionCallCount = 0
    private(set) var receiptCallCount = 0

    private(set) var lastCreateWalletPassword: String?
    private(set) var lastCreateWalletKDF: KDF?
    private(set) var lastRestoration: KeyRestoration?
    private(set) var lastVerifyPassword: String?
    private(set) var lastBalanceAddress: LegacyAddress?
    private(set) var lastSendTransactionPassword: String?
    private(set) var lastReceiptTxId: String?

    func getNetworkFromAPI() -> AnyPublisher<NetworkResponse, Zesame.Error> {
        getNetworkCallCount += 1
        return Self.publisher(for: networkResult)
    }

    func getMinimumGasPrice(alsoUpdateLocallyCachedMinimum _: Bool)
        -> AnyPublisher<MinimumGasPriceResponse, Zesame.Error>
    {
        getMinimumGasPriceCallCount += 1
        return Self.publisher(for: minimumGasPriceResult)
    }

    func verifyThat(encryptionPassword: String, canDecryptKeystore _: Keystore)
        -> AnyPublisher<Bool, Zesame.Error>
    {
        verifyEncryptionPasswordCallCount += 1
        lastVerifyPassword = encryptionPassword
        return Self.publisher(for: verifyEncryptionPasswordResult)
    }

    func createNewWallet(encryptionPassword: String, kdf: KDF)
        -> AnyPublisher<Zesame.Wallet, Zesame.Error>
    {
        createNewWalletCallCount += 1
        lastCreateWalletPassword = encryptionPassword
        lastCreateWalletKDF = kdf
        return Self.publisher(for: createNewWalletResult)
    }

    func restoreWallet(from restoration: KeyRestoration)
        -> AnyPublisher<Zesame.Wallet, Zesame.Error>
    {
        restoreWalletCallCount += 1
        lastRestoration = restoration
        return Self.publisher(for: restoreWalletResult)
    }

    func exportKeystore(privateKey _: PrivateKey, encryptWalletBy _: String)
        -> AnyPublisher<Keystore, Zesame.Error>
    {
        Empty<Keystore, Zesame.Error>().eraseToAnyPublisher()
    }

    func extractKeyPairFrom(keystore _: Keystore, encryptedBy _: String)
        -> AnyPublisher<KeyPair, Zesame.Error>
    {
        extractKeyPairCallCount += 1
        return Self.publisher(for: extractKeyPairResult)
    }

    func getBalance(for address: LegacyAddress) -> AnyPublisher<BalanceResponse, Zesame.Error> {
        getBalanceCallCount += 1
        lastBalanceAddress = address
        return Self.publisher(for: balanceResult)
    }

    func sendTransaction(for _: Payment, keystore _: Keystore, password: String, network _: Network)
        -> AnyPublisher<TransactionResponse, Zesame.Error>
    {
        sendTransactionCallCount += 1
        lastSendTransactionPassword = password
        return Self.publisher(for: sendTransactionResult)
    }

    func sendTransaction(for _: Payment, signWith _: KeyPair, network _: Network)
        -> AnyPublisher<TransactionResponse, Zesame.Error>
    {
        Self.publisher(for: sendTransactionResult)
    }

    func hasNetworkReachedConsensusYetForTransactionWith(id: String, polling _: Polling)
        -> AnyPublisher<TransactionReceipt, Zesame.Error>
    {
        receiptCallCount += 1
        lastReceiptTxId = id
        return Self.publisher(for: transactionReceiptResult)
    }

    private static func publisher<T>(for result: Result<T, Zesame.Error>?) -> AnyPublisher<T, Zesame.Error> {
        guard let result else { return Empty<T, Zesame.Error>().eraseToAnyPublisher() }
        switch result {
        case let .success(value):
            return Just(value).setFailureType(to: Zesame.Error.self).eraseToAnyPublisher()
        case let .failure(error):
            return Fail<T, Zesame.Error>(error: error).eraseToAnyPublisher()
        }
    }
}
