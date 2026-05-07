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

import Factory
import Foundation
import KeychainSwift
import NanoViewControllerDIPrimitives
import Zesame

/// The Zilliqa network this build targets. Currently wired to `.mainnet`. When we
/// add staging/testnet builds this will move into a build-configuration driven
/// registration on `Container.shared.zilliqaService`.
///
/// `Network` gains `Sendable` retroactively in `Concurrency/Sendable+Zesame.swift`,
/// so this `let`-bound global needs no concurrency escape hatch.
let network: Network = .mainnet

extension KeyValueStore where KeyType == PreferencesKey {
    /// The app-wide default `Preferences` store, backed by `UserDefaults.standard`.
    static var `default`: Preferences {
        KeyValueStore(UserDefaults.standard)
    }
}

// MARK: - Services

public extension Container {
    /// The reactive façade over `Zesame` blockchain operations. Shared across every
    /// use case so they all talk to the same underlying service instance.
    var zilliqaService: Factory<ZilliqaServiceReactive> {
        self { DefaultZilliqaService(network: network).combine }.singleton
    }

    /// The `UserDefaults`-backed key-value store for non-secret preferences.
    var preferences: Factory<Preferences> {
        self { KeyValueStore(UserDefaults.standard) }.singleton
    }

    /// The Keychain-backed secure store for wallet material and pincode.
    var securePersistence: Factory<SecurePersistence> {
        self { KeyValueStore(KeychainSwift()) }.singleton
    }

    /// Deep-link URL builder for outbound sharing (e.g. receive links).
    var deepLinkGenerator: Factory<DeepLinkGenerator> {
        self { DefaultDeepLinkGenerator() }
    }

    /// Universal-link dispatcher. Singleton because the buffered link must
    /// survive the lock/unlock boundary — `AppDelegate` writes (on URL
    /// receipt), `AppCoordinator` reads (on unlock), and the unlock-flow
    /// publisher in between needs both sides to share the same instance.
    /// Tests override via `Container.shared.deepLinkHandler.register { … }`
    /// to install a fresh handler per test (Factory's `register` shadows
    /// `.singleton`).
    var deepLinkHandler: Factory<DeepLinkHandler> {
        self { mainActorOnly { DeepLinkHandler() } }.singleton
    }

    /// Plays bundled sound effects. Tests register a no-op so unit tests never
    /// produce real audio.
    var soundPlayer: Factory<SoundPlayer> {
        self { DefaultSoundPlayer() }.singleton
    }

    /// Abstracts `UIPasteboard.general`. Tests register a `MockPasteboard` so
    /// unit tests never mutate the real simulator pasteboard.
    var pasteboard: Factory<Pasteboard> {
        // `DefaultPasteboard.init` is `@MainActor` (wraps UIPasteboard);
        // Factory's resolver is `@Sendable` so we hop via `assumeIsolated`.
        // Container singletons are always resolved from the main thread in
        // this app, so the assumption holds.
        self { mainActorOnly { DefaultPasteboard() } }.singleton
    }

    /// Abstracts `LAContext` biometric authentication. Tests register a mock
    /// so unit tests never trigger a real Face ID / Touch ID prompt.
    var biometricsAuthenticator: Factory<BiometricsAuthenticator> {
        self { LAContextBiometricsAuthenticator() }.singleton
    }

    /// QR code encoder/decoder. Stateless, so a fresh instance per resolve is
    /// fine. Tests can register a stub when they want to observe encode/decode
    /// calls without hitting CoreImage.
    var qrCoder: Factory<QRCoding> {
        self { QRCoder() }
    }

    /// Abstracts `UIApplication.shared.open(_:)`. Tests register a mock so
    /// unit tests never trigger a real OS-level URL open (which can hang the
    /// iOS simulator runloop).
    var urlOpener: Factory<UrlOpener> {
        // See `pasteboard` above for why `assumeIsolated` — DefaultUrlOpener
        // wraps UIApplication and is therefore main-actor-isolated.
        self { mainActorOnly { DefaultUrlOpener() } }.singleton
    }

    /// Abstracts delayed main-queue dispatch (`asyncAfter`). Tests register
    /// `ImmediateClock`, which ignores the requested delay and fires on the
    /// next main-queue cycle, so timer-driven flows run in milliseconds
    /// instead of seconds.
    var clock: Factory<Clock> {
        self { mainActorOnly { MainQueueClock() } }.singleton
    }

    /// Abstracts immediate main-thread scheduling (the Combine
    /// `.receive(on: DispatchQueue.main)` hop used by navigation plumbing).
    /// Tests register `ImmediateMainScheduler`, which invokes work
    /// synchronously so coordinator tests can assert on navigation side
    /// effects without pumping the runloop.
    var mainScheduler: Factory<MainScheduler> {
        self { mainActorOnly { DispatchMainScheduler() } }.singleton
    }

    /// Loads bundled HTML files into attributed strings. Production uses
    /// WebKit-backed parsing which can block the main thread for seconds on CI
    /// simulators; tests register a stub that returns an empty string so view
    /// lifecycle completes immediately when modal presentation is synchronous.
    var htmlLoader: Factory<HtmlLoader> {
        self { DefaultHtmlLoader() }.singleton
    }

    /// Abstracts `UINotificationFeedbackGenerator`. Tests register a mock so
    /// unit tests never trigger real device vibrations.
    var hapticFeedback: Factory<HapticFeedback> {
        // See `pasteboard` above — DefaultHapticFeedback wraps a
        // UINotificationFeedbackGenerator and is main-actor-isolated.
        self { mainActorOnly { DefaultHapticFeedback() } }.singleton
    }

    /// Abstracts "what time is it now" so timestamp-dependent logic
    /// (balance-last-updated, relative date formatting) is testable with a
    /// fixed instant.
    var dateProvider: Factory<DateProvider> {
        self { DefaultDateProvider() }.singleton
    }
}

// MARK: - Composite use cases (subsystems that remain monolithic)

public extension Container {
    var transactionsUseCase: Factory<TransactionsUseCase> {
        self {
            DefaultTransactionsUseCase(
                zilliqaService: self.zilliqaService(),
                securePersistence: self.securePersistence(),
                preferences: self.preferences()
            )
        }
        .singleton
    }

    var onboardingUseCase: Factory<OnboardingUseCase> {
        self {
            DefaultOnboardingUseCase(
                zilliqaService: self.zilliqaService(),
                preferences: self.preferences(),
                securePersistence: self.securePersistence()
            )
        }
        .singleton
    }

    var pincodeUseCase: Factory<PincodeUseCase> {
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

public extension Container {
    var createWalletUseCase: Factory<CreateWalletUseCase> {
        self { DefaultCreateWalletUseCase() }
    }

    var restoreWalletUseCase: Factory<RestoreWalletUseCase> {
        self { DefaultRestoreWalletUseCase() }
    }

    var walletStorageUseCase: Factory<WalletStorageUseCase> {
        self { DefaultWalletStorageUseCase() }.singleton
    }

    var verifyEncryptionPasswordUseCase: Factory<VerifyEncryptionPasswordUseCase> {
        self { DefaultVerifyEncryptionPasswordUseCase() }
    }

    var extractKeyPairUseCase: Factory<ExtractKeyPairUseCase> {
        self { DefaultExtractKeyPairUseCase() }
    }
}

// MARK: - Narrow transactions use cases

public extension Container {
    var balanceCacheUseCase: Factory<BalanceCacheUseCase> {
        self { self.transactionsUseCase() }
    }

    var gasPriceUseCase: Factory<GasPriceUseCase> {
        self { self.transactionsUseCase() }
    }

    var fetchBalanceUseCase: Factory<FetchBalanceUseCase> {
        self { self.transactionsUseCase() }
    }

    var sendTransactionUseCase: Factory<SendTransactionUseCase> {
        self { self.transactionsUseCase() }
    }

    var transactionReceiptUseCase: Factory<TransactionReceiptUseCase> {
        self { self.transactionsUseCase() }
    }
}
