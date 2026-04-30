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
import Foundation
import Zesame

/// Hand-written mock conforming to every narrow wallet use-case protocol for
/// ViewModel tests.
///
/// Each async method is backed by a `*Result` property tests can seed. Storage
/// methods update a local `storedWallet` property and increment call counters.
final class MockWalletUseCase: CreateWalletUseCase,
    RestoreWalletUseCase,
    WalletStorageUseCase,
    VerifyEncryptionPasswordUseCase,
    ExtractKeyPairUseCase
{
    // MARK: - State

    var storedWallet: AppFeature.Wallet?

    var createWalletResult: Result<AppFeature.Wallet, Swift.Error> = .success(TestWalletFactory.makeWallet())
    var restoreWalletResult: Result<AppFeature.Wallet, Swift.Error> = .success(TestWalletFactory
        .makeWallet(origin: .importedKeystore))
    var verifyPasswordResult: Result<Bool, Swift.Error> = .success(true)
    var extractKeyPairResult: Result<KeyPair, Swift.Error>?

    // MARK: - Call counters / last args

    private(set) var createNewWalletCallCount = 0
    private(set) var lastCreateEncryptionPassword: String?

    private(set) var restoreWalletCallCount = 0
    private(set) var lastRestoreInput: KeyRestoration?

    private(set) var saveWalletCallCount = 0
    private(set) var deleteWalletCallCount = 0
    private(set) var verifyPasswordCallCount = 0
    private(set) var extractKeyPairCallCount = 0

    // MARK: - CreateWalletUseCase

    func createNewWallet(encryptionPassword: String) -> AnyPublisher<AppFeature.Wallet, Swift.Error> {
        createNewWalletCallCount += 1
        lastCreateEncryptionPassword = encryptionPassword
        return publisher(for: createWalletResult)
    }

    // MARK: - RestoreWalletUseCase

    func restoreWallet(from restoration: KeyRestoration) -> AnyPublisher<AppFeature.Wallet, Swift.Error> {
        restoreWalletCallCount += 1
        lastRestoreInput = restoration
        return publisher(for: restoreWalletResult)
    }

    // MARK: - WalletStorageUseCase

    func save(wallet: AppFeature.Wallet) {
        saveWalletCallCount += 1
        storedWallet = wallet
    }

    func deleteWallet() {
        deleteWalletCallCount += 1
        storedWallet = nil
    }

    func loadWallet() -> AppFeature.Wallet? {
        storedWallet
    }

    var hasConfiguredWallet: Bool {
        storedWallet != nil
    }

    // MARK: - VerifyEncryptionPasswordUseCase

    func verify(password _: String, forKeystore _: Keystore) -> AnyPublisher<Bool, Swift.Error> {
        verifyPasswordCallCount += 1
        return publisher(for: verifyPasswordResult)
    }

    // MARK: - ExtractKeyPairUseCase

    func extractKeyPairFrom(keystore: Keystore, encryptedBy password: String) -> AnyPublisher<KeyPair, Swift.Error> {
        extractKeyPairCallCount += 1
        if let result = extractKeyPairResult {
            return publisher(for: result)
        }
        // Derive a real key pair from the keystore when none is pre-seeded.
        do {
            let privateKey = try keystore.decryptPrivateKey(encryptedBy: password)
            let keyPair = KeyPair(private: privateKey)
            return Just(keyPair).setFailureType(to: Swift.Error.self).eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
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
