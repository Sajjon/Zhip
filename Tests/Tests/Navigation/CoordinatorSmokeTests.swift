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
import Factory
import UIKit
import XCTest
import Zesame

/// Smoke tests that coordinator `.start()` pushes an initial scene onto the
/// supplied `UINavigationController`.
@MainActor
final class CoordinatorSmokeTests: XCTestCase {
    private var mockTransactions: MockTransactionsUseCase!
    private var mockWallet: MockWalletUseCase!
    private var mockPincode: MockPincodeUseCase!

    override func setUp() {
        super.setUp()
        mockTransactions = MockTransactionsUseCase()
        mockWallet = MockWalletUseCase()
        mockWallet.storedWallet = TestWalletFactory.makeWallet()
        mockPincode = MockPincodeUseCase()
        Container.shared.transactionsUseCase.register { [unowned self] in MainActor.assumeIsolated { mockTransactions } }
        Container.shared.walletStorageUseCase.register { [unowned self] in MainActor.assumeIsolated { mockWallet } }
        Container.shared.pincodeUseCase.register { [unowned self] in MainActor.assumeIsolated { mockPincode } }
    }

    override func tearDown() {
        Container.shared.manager.reset()
        mockPincode = nil
        mockWallet = nil
        mockTransactions = nil
        super.tearDown()
    }

    func test_sendCoordinator_start_pushesPrepareTransaction() {
        let nav = UINavigationController()
        let sut = SendCoordinator(
            navigationController: nav,
            deeplinkedTransaction: Empty<TransactionIntent, Never>().eraseToAnyPublisher()
        )

        sut.start()

        XCTAssertEqual(nav.viewControllers.count, 1)
    }

    func test_receiveCoordinator_start_pushesReceive() {
        let nav = UINavigationController()
        let sut = ReceiveCoordinator(navigationController: nav)

        sut.start()

        XCTAssertEqual(nav.viewControllers.count, 1)
    }

    func test_settingsCoordinator_start_pushesSettings() {
        let nav = UINavigationController()
        let sut = SettingsCoordinator(navigationController: nav)

        sut.start()

        XCTAssertEqual(nav.viewControllers.count, 1)
    }

    func test_backupWalletCoordinator_start_pushesBackup() {
        let nav = UINavigationController()
        let walletSubject = CurrentValueSubject<AppFeature.Wallet, Never>(TestWalletFactory.makeWallet())
        let sut = BackupWalletCoordinator(
            navigationController: nav,
            wallet: walletSubject.eraseToAnyPublisher()
        )

        sut.start()

        XCTAssertEqual(nav.viewControllers.count, 1)
    }

    func test_chooseWalletCoordinator_start_pushesChoose() {
        let nav = UINavigationController()
        let sut = ChooseWalletCoordinator(navigationController: nav)

        sut.start()

        XCTAssertEqual(nav.viewControllers.count, 1)
    }

    func test_createNewWalletCoordinator_start_pushesCreateWallet() {
        let nav = UINavigationController()
        let sut = CreateNewWalletCoordinator(navigationController: nav)

        sut.start()

        XCTAssertEqual(nav.viewControllers.count, 1)
    }

    func test_decryptKeystoreCoordinator_start_pushesDecrypt() {
        let nav = UINavigationController()
        let walletSubject = CurrentValueSubject<AppFeature.Wallet, Never>(TestWalletFactory.makeWallet())
        let sut = DecryptKeystoreCoordinator(
            navigationController: nav,
            wallet: walletSubject.eraseToAnyPublisher()
        )

        sut.start()

        XCTAssertEqual(nav.viewControllers.count, 1)
    }

    func test_restoreWalletCoordinator_start_pushesRestore() {
        let nav = UINavigationController()
        let sut = RestoreWalletCoordinator(navigationController: nav)

        sut.start()

        XCTAssertEqual(nav.viewControllers.count, 1)
    }

    func test_setPincodeCoordinator_start_pushesChoosePincode() {
        let nav = UINavigationController()
        let sut = SetPincodeCoordinator(navigationController: nav, useCase: mockPincode)

        sut.start()

        XCTAssertEqual(nav.viewControllers.count, 1)
    }
}
