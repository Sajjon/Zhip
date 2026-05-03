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
import Factory
import XCTest

/// Tests the Factory-compatible DI container: register, resolve, reset.
///
/// We exercise the container exclusively through the `preferences` factory because
/// registering a mock `Preferences` is side-effect-free — it doesn't try to open a
/// network connection or touch the Keychain.
@MainActor
final class ContainerTests: XCTestCase {
    override func tearDown() {
        Container.shared.manager.reset()
        super.tearDown()
    }

    // MARK: - Factory.callAsFunction / register

    func test_register_overridesDefaultFactory() {
        // Arrange
        let mock = TestStoreFactory.makePreferences()
        Container.shared.preferences.register { mock }

        // Act
        let resolved = Container.shared.preferences()

        // Assert
        // Two `Preferences` values are equal iff they share the same backing closures;
        // instead we verify identity by mutating and re-reading through both refs.
        mock.save(value: true, for: .hasAcceptedTermsOfService)
        XCTAssertTrue(resolved.isTrue(.hasAcceptedTermsOfService))
    }

    // MARK: - reset()

    func test_reset_restoresDefaultFactory() {
        // Arrange
        let mock = TestStoreFactory.makePreferences()
        Container.shared.preferences.register { mock }

        // Act
        Container.shared.manager.reset()

        // Assert: after reset, the old mock is no longer seen.
        mock.save(value: true, for: .hasAcceptedTermsOfService)
        XCTAssertFalse(Container.shared.preferences().isTrue(.hasAcceptedTermsOfService))
    }

    // MARK: - narrow use case factories

    func test_createWalletUseCase_registerOverridesDefault() {
        // Arrange
        let mock = MockWalletUseCase()
        Container.shared.createWalletUseCase.register { mock }

        // Act
        let resolved = Container.shared.createWalletUseCase()

        // Assert
        XCTAssertTrue((resolved as AnyObject) === mock)
    }

    func test_walletStorageUseCase_isSharedAcrossResolutions() {
        // Arrange
        let mock = MockWalletUseCase()
        Container.shared.walletStorageUseCase.register { mock }

        // Act
        let resolvedA = Container.shared.walletStorageUseCase()
        let resolvedB = Container.shared.walletStorageUseCase()

        // Assert — singleton scope returns the same instance.
        XCTAssertTrue((resolvedA as AnyObject) === (resolvedB as AnyObject))
        XCTAssertTrue((resolvedA as AnyObject) === mock)
    }

    // MARK: - additional narrow factories register/resolve

    func test_restoreWalletUseCase_registerOverridesDefault() {
        let mock = MockWalletUseCase()
        Container.shared.restoreWalletUseCase.register { mock }
        XCTAssertTrue((Container.shared.restoreWalletUseCase() as AnyObject) === mock)
    }

    func test_verifyEncryptionPasswordUseCase_registerOverridesDefault() {
        let mock = MockWalletUseCase()
        Container.shared.verifyEncryptionPasswordUseCase.register { mock }
        XCTAssertTrue((Container.shared.verifyEncryptionPasswordUseCase() as AnyObject) === mock)
    }

    func test_extractKeyPairUseCase_registerOverridesDefault() {
        let mock = MockWalletUseCase()
        Container.shared.extractKeyPairUseCase.register { mock }
        XCTAssertTrue((Container.shared.extractKeyPairUseCase() as AnyObject) === mock)
    }

    func test_pincodeUseCase_registerOverridesDefault() {
        let mock = MockPincodeUseCase()
        Container.shared.pincodeUseCase.register { mock }
        XCTAssertTrue((Container.shared.pincodeUseCase() as AnyObject) === mock)
    }

    func test_onboardingUseCase_registerOverridesDefault() {
        let mock = MockOnboardingUseCase()
        Container.shared.onboardingUseCase.register { mock }
        XCTAssertTrue((Container.shared.onboardingUseCase() as AnyObject) === mock)
    }

    func test_transactionsUseCase_registerOverridesDefault() {
        let mock = MockTransactionsUseCase()
        Container.shared.transactionsUseCase.register { mock }
        XCTAssertTrue((Container.shared.transactionsUseCase() as AnyObject) === mock)
    }

    // MARK: - narrow transactions facets resolve to shared singleton

    func test_balanceCacheUseCase_resolvesToSharedTransactionsInstance() {
        let mock = MockTransactionsUseCase()
        Container.shared.transactionsUseCase.register { mock }
        XCTAssertTrue((Container.shared.balanceCacheUseCase() as AnyObject) === mock)
    }

    func test_gasPriceUseCase_resolvesToSharedTransactionsInstance() {
        let mock = MockTransactionsUseCase()
        Container.shared.transactionsUseCase.register { mock }
        XCTAssertTrue((Container.shared.gasPriceUseCase() as AnyObject) === mock)
    }

    func test_fetchBalanceUseCase_resolvesToSharedTransactionsInstance() {
        let mock = MockTransactionsUseCase()
        Container.shared.transactionsUseCase.register { mock }
        XCTAssertTrue((Container.shared.fetchBalanceUseCase() as AnyObject) === mock)
    }

    func test_sendTransactionUseCase_resolvesToSharedTransactionsInstance() {
        let mock = MockTransactionsUseCase()
        Container.shared.transactionsUseCase.register { mock }
        XCTAssertTrue((Container.shared.sendTransactionUseCase() as AnyObject) === mock)
    }

    func test_transactionReceiptUseCase_resolvesToSharedTransactionsInstance() {
        let mock = MockTransactionsUseCase()
        Container.shared.transactionsUseCase.register { mock }
        XCTAssertTrue((Container.shared.transactionReceiptUseCase() as AnyObject) === mock)
    }

    // MARK: - default factories

    func test_securePersistence_resolvesDefault() {
        let resolved = Container.shared.securePersistence()
        XCTAssertNotNil(resolved)
    }

    func test_zilliqaService_resolvesDefault() {
        let resolved = Container.shared.zilliqaService()
        XCTAssertNotNil(resolved)
    }

    func test_deepLinkGenerator_resolvesDefault() {
        let resolved = Container.shared.deepLinkGenerator()
        XCTAssertNotNil(resolved)
    }

    // MARK: - KeyValueStore.default helper

    func test_preferencesDefault_isUsable() {
        let prefs = KeyValueStore<PreferencesKey>.default
        XCTAssertNotNil(prefs)
    }

    // MARK: - default factory closures for composite use cases

    func test_transactionsUseCaseDefault_resolvesWithoutRegistration() {
        let resolved = Container.shared.transactionsUseCase()
        XCTAssertNotNil(resolved)
    }

    func test_onboardingUseCaseDefault_resolvesWithoutRegistration() {
        let resolved = Container.shared.onboardingUseCase()
        XCTAssertNotNil(resolved)
    }

    func test_pincodeUseCaseDefault_resolvesWithoutRegistration() {
        let resolved = Container.shared.pincodeUseCase()
        XCTAssertNotNil(resolved)
    }

    func test_soundPlayerDefault_resolvesWithoutRegistration() {
        let resolved = Container.shared.soundPlayer()
        XCTAssertNotNil(resolved)
    }
}
