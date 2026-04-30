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

import Factory
import Foundation
import KeychainSwift
import Zesame
import SingleLineControllerDIPrimitives

/// The Zilliqa network this build targets. Currently wired to `.mainnet`. When we
/// add staging/testnet builds this will move into a build-configuration driven
/// registration on `Container.shared.zilliqaService`.
public let network: Network = .mainnet

extension KeyValueStore where KeyType == PreferencesKey {
    /// The app-wide default `Preferences` store, backed by `UserDefaults.standard`.
    static var `default`: Preferences {
        KeyValueStore(UserDefaults.standard)
    }
}

// MARK: - Services

extension Container {
    /// The reactive façade over `Zesame` blockchain operations. Shared across every
    /// use case so they all talk to the same underlying service instance.
    public var zilliqaService: Factory<ZilliqaServiceReactive> {
        self { DefaultZilliqaService(network: network).combine }.singleton
    }

    /// The `UserDefaults`-backed key-value store for non-secret preferences.
    public var preferences: Factory<Preferences> {
        self { KeyValueStore(UserDefaults.standard) }.singleton
    }

    /// The Keychain-backed secure store for wallet material and pincode.
    public var securePersistence: Factory<SecurePersistence> {
        self { KeyValueStore(KeychainSwift()) }.singleton
    }

    /// Deep-link URL builder for outbound sharing (e.g. receive links).
    public var deepLinkGenerator: Factory<DeepLinkGenerator> {
        self { DefaultDeepLinkGenerator() }
    }

    /// Universal-link dispatcher. Singleton because the buffered link must
    /// survive the lock/unlock boundary — `AppDelegate` writes (on URL
    /// receipt), `AppCoordinator` reads (on unlock), and the unlock-flow
    /// publisher in between needs both sides to share the same instance.
    /// Tests override via `Container.shared.deepLinkHandler.register { … }`
    /// to install a fresh handler per test (Factory's `register` shadows
    /// `.singleton`).
    public var deepLinkHandler: Factory<DeepLinkHandler> {
        self { DeepLinkHandler() }.singleton
    }

    /// Plays bundled sound effects. Tests register a no-op so unit tests never
    /// produce real audio.
    public var soundPlayer: Factory<SoundPlayer> {
        self { DefaultSoundPlayer() }.singleton
    }

    /// Abstracts `UIPasteboard.general`. Tests register a `MockPasteboard` so
    /// unit tests never mutate the real simulator pasteboard.
    public var pasteboard: Factory<Pasteboard> {
        self { DefaultPasteboard() }.singleton
    }

    /// Abstracts `LAContext` biometric authentication. Tests register a mock
    /// so unit tests never trigger a real Face ID / Touch ID prompt.
    public var biometricsAuthenticator: Factory<BiometricsAuthenticator> {
        self { LAContextBiometricsAuthenticator() }.singleton
    }

    /// QR code encoder/decoder. Stateless, so a fresh instance per resolve is
    /// fine. Tests can register a stub when they want to observe encode/decode
    /// calls without hitting `EFQRCode`.
    public var qrCoder: Factory<QRCoding> {
        self { QRCoder() }
    }

    /// Abstracts `UIApplication.shared.open(_:)`. Tests register a mock so
    /// unit tests never trigger a real OS-level URL open (which can hang the
    /// iOS simulator runloop).
    public var urlOpener: Factory<UrlOpener> {
        self { DefaultUrlOpener() }.singleton
    }

    /// Abstracts delayed main-queue dispatch (`asyncAfter`). Tests register
    /// `ImmediateClock`, which ignores the requested delay and fires on the
    /// next main-queue cycle, so timer-driven flows run in milliseconds
    /// instead of seconds.
    public var clock: Factory<Clock> {
        self { MainQueueClock() }.singleton
    }

    /// Abstracts immediate main-thread scheduling (the Combine
    /// `.receive(on: DispatchQueue.main)` hop used by navigation plumbing).
    /// Tests register `ImmediateMainScheduler`, which invokes work
    /// synchronously so coordinator tests can assert on navigation side
    /// effects without pumping the runloop.
    public var mainScheduler: Factory<MainScheduler> {
        self { DispatchMainScheduler() }.singleton
    }

    /// Loads bundled HTML files into attributed strings. Production uses
    /// WebKit-backed parsing which can block the main thread for seconds on CI
    /// simulators; tests register a stub that returns an empty string so view
    /// lifecycle completes immediately when modal presentation is synchronous.
    public var htmlLoader: Factory<HtmlLoader> {
        self { DefaultHtmlLoader() }.singleton
    }

    /// Abstracts `UINotificationFeedbackGenerator`. Tests register a mock so
    /// unit tests never trigger real device vibrations.
    public var hapticFeedback: Factory<HapticFeedback> {
        self { DefaultHapticFeedback() }.singleton
    }

    /// Abstracts "what time is it now" so timestamp-dependent logic
    /// (balance-last-updated, relative date formatting) is testable with a
    /// fixed instant.
    public var dateProvider: Factory<DateProvider> {
        self { DefaultDateProvider() }.singleton
    }
}

// MARK: - Composite use cases (subsystems that remain monolithic)

extension Container {
    public var transactionsUseCase: Factory<TransactionsUseCase> {
        self {
            DefaultTransactionsUseCase(
                zilliqaService: self.zilliqaService(),
                securePersistence: self.securePersistence(),
                preferences: self.preferences()
            )
        }
        .singleton
    }

    public var onboardingUseCase: Factory<OnboardingUseCase> {
        self {
            DefaultOnboardingUseCase(
                zilliqaService: self.zilliqaService(),
                preferences: self.preferences(),
                securePersistence: self.securePersistence()
            )
        }
        .singleton
    }

    public var pincodeUseCase: Factory<PincodeUseCase> {
        self {
            DefaultPincodeUseCase(
                preferences: self.preferences(),
                securePersistence: self.securePersistence()
            )
        }
        .singleton
    }
}

// MARK: - Narrow wallet use cases

extension Container {
    public var createWalletUseCase: Factory<CreateWalletUseCase> {
        self { DefaultCreateWalletUseCase() }
    }

    public var restoreWalletUseCase: Factory<RestoreWalletUseCase> {
        self { DefaultRestoreWalletUseCase() }
    }

    public var walletStorageUseCase: Factory<WalletStorageUseCase> {
        self { DefaultWalletStorageUseCase() }.singleton
    }

    public var verifyEncryptionPasswordUseCase: Factory<VerifyEncryptionPasswordUseCase> {
        self { DefaultVerifyEncryptionPasswordUseCase() }
    }

    public var extractKeyPairUseCase: Factory<ExtractKeyPairUseCase> {
        self { DefaultExtractKeyPairUseCase() }
    }
}

// MARK: - Narrow transactions use cases

extension Container {
    public var balanceCacheUseCase: Factory<BalanceCacheUseCase> {
        self { self.transactionsUseCase() }
    }

    public var gasPriceUseCase: Factory<GasPriceUseCase> {
        self { self.transactionsUseCase() }
    }

    public var fetchBalanceUseCase: Factory<FetchBalanceUseCase> {
        self { self.transactionsUseCase() }
    }

    public var sendTransactionUseCase: Factory<SendTransactionUseCase> {
        self { self.transactionsUseCase() }
    }

    public var transactionReceiptUseCase: Factory<TransactionReceiptUseCase> {
        self { self.transactionsUseCase() }
    }
}
