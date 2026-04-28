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
import Factory
import XCTest
import Zesame
import SingleLineControllerController
@testable import Zhip

/// Tests for `BackupWalletViewModel`.
///
/// Exercises both `.cancellable` and `.dismissable` modes (left vs. right bar
/// button wiring), the three user-intent branches (reveal keystore, reveal
/// private key, done-after-understanding-risk), the keystore copy side effect,
/// and the visibility flag driven by the mode.
final class BackupWalletViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var copyKeystore: PassthroughSubject<Void, Never>!
    private var revealKeystore: PassthroughSubject<Void, Never>!
    private var revealPrivateKey: PassthroughSubject<Void, Never>!
    private var isUnderstandsRisk: CurrentValueSubject<Bool, Never>!
    private var doneTrigger: PassthroughSubject<Void, Never>!
    private var fakeController: FakeInputFromController!
    private var wallet: Zhip.Wallet!
    private var mockPasteboard: MockPasteboard!

    override func setUp() {
        super.setUp()
        copyKeystore = PassthroughSubject<Void, Never>()
        revealKeystore = PassthroughSubject<Void, Never>()
        revealPrivateKey = PassthroughSubject<Void, Never>()
        isUnderstandsRisk = CurrentValueSubject<Bool, Never>(false)
        doneTrigger = PassthroughSubject<Void, Never>()
        fakeController = FakeInputFromController()
        wallet = TestWalletFactory.makeWallet()
        mockPasteboard = MockPasteboard()
        Container.shared.pasteboard.register { [unowned self] in mockPasteboard }
    }

    override func tearDown() {
        cancellables.removeAll()
        Container.shared.manager.reset()
        mockPasteboard = nil
        wallet = nil
        fakeController = nil
        doneTrigger = nil
        isUnderstandsRisk = nil
        revealPrivateKey = nil
        revealKeystore = nil
        copyKeystore = nil
        super.tearDown()
    }

    // MARK: - Navigation

    func test_cancellable_leftBarButton_emitsCancelOrDismiss() {
        let sut = makeSUT(mode: .cancellable)
        _ = sut.transform(input: makeInput())
        var observed: BackupWalletUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        fakeController.leftBarButtonTriggerSubject.send(())

        guard case .cancelOrDismiss = observed else {
            return XCTFail("Expected .cancelOrDismiss, got \(String(describing: observed))")
        }
    }

    func test_dismissable_rightBarButton_emitsCancelOrDismiss() {
        let sut = makeSUT(mode: .dismissable)
        _ = sut.transform(input: makeInput())
        var observed: BackupWalletUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        fakeController.rightBarButtonTriggerSubject.send(())

        guard case .cancelOrDismiss = observed else {
            return XCTFail("Expected .cancelOrDismiss, got \(String(describing: observed))")
        }
    }

    func test_revealKeystoreTrigger_emitsRevealKeystore() {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var observed: BackupWalletUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        revealKeystore.send(())

        guard case .revealKeystore = observed else {
            return XCTFail("Expected .revealKeystore, got \(String(describing: observed))")
        }
    }

    func test_revealPrivateKeyTrigger_emitsRevealPrivateKey() {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var observed: BackupWalletUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        revealPrivateKey.send(())

        guard case .revealPrivateKey = observed else {
            return XCTFail("Expected .revealPrivateKey, got \(String(describing: observed))")
        }
    }

    // MARK: - Done gate

    func test_doneTrigger_withoutAgreement_doesNotEmit() {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var observed: BackupWalletUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        isUnderstandsRisk.send(false)
        doneTrigger.send(())

        XCTAssertNil(observed)
    }

    func test_doneTrigger_withAgreement_emitsBackupWallet() {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var observed: BackupWalletUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        isUnderstandsRisk.send(true)
        doneTrigger.send(())

        guard case .backupWallet = observed else {
            return XCTFail("Expected .backupWallet, got \(String(describing: observed))")
        }
    }

    // MARK: - Copy keystore side effect

    func test_copyKeystoreTrigger_writesKeystoreJSONToPasteboardAndSendsToast() {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var toasts: [Toast] = []
        fakeController.toastSubject.sink { toasts.append($0) }.store(in: &cancellables)

        copyKeystore.send(())

        XCTAssertEqual(toasts.count, 1)
        let pasted = mockPasteboard.copiedString ?? ""
        XCTAssertTrue(pasted.contains(wallet.keystore.address.asString))
        XCTAssertTrue(pasted.contains("\"version\""))
    }

    // MARK: - Output

    func test_output_isHaveSecurelyBackedUpViewsVisible_reflectsMode() {
        let sutCancellable = makeSUT(mode: .cancellable)
        let outCancellable = sutCancellable.transform(input: makeInput())
        var cancellableVisible: Bool?
        outCancellable.isHaveSecurelyBackedUpViewsVisible.sink { cancellableVisible = $0 }
            .store(in: &cancellables)

        let sutDismissable = makeSUT(mode: .dismissable)
        let outDismissable = sutDismissable.transform(input: makeInput())
        var dismissableVisible: Bool?
        outDismissable.isHaveSecurelyBackedUpViewsVisible.sink { dismissableVisible = $0 }
            .store(in: &cancellables)

        XCTAssertEqual(cancellableVisible, true)
        XCTAssertEqual(dismissableVisible, false)
    }

    private func makeSUT(mode: BackupWalletViewModel.Mode = .cancellable) -> BackupWalletViewModel {
        BackupWalletViewModel(wallet: Just(wallet).eraseToAnyPublisher(), mode: mode)
    }

    private func makeInput() -> BackupWalletViewModel.Input {
        BackupWalletViewModel.Input(
            fromView: .init(
                copyKeystoreToPasteboardTrigger: copyKeystore.eraseToAnyPublisher(),
                revealKeystoreTrigger: revealKeystore.eraseToAnyPublisher(),
                revealPrivateKeyTrigger: revealPrivateKey.eraseToAnyPublisher(),
                isUnderstandsRiskCheckboxChecked: isUnderstandsRisk.eraseToAnyPublisher(),
                doneTrigger: doneTrigger.eraseToAnyPublisher()
            ),
            fromController: fakeController.makeInput()
        )
    }
}
