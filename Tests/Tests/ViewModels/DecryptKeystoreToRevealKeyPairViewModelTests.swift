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

/// Tests for `DecryptKeystoreToRevealKeyPairViewModel`.
///
/// Covers dismiss-from-right-bar-button, the password-validation gate on the
/// reveal button, and the decryption flow that reaches into
/// `ExtractKeyPairUseCase` and emits `.decryptKeystoreReavealing` with the
/// derived key pair.
final class DecryptKeystoreToRevealKeyPairViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var encryptionPassword: CurrentValueSubject<String, Never>!
    private var isEditingEncryptionPassword: CurrentValueSubject<Bool, Never>!
    private var revealTrigger: PassthroughSubject<Void, Never>!
    private var fakeController: FakeInputFromController!
    private var mockWallet: MockWalletUseCase!
    private var wallet: Zhip.Wallet!

    override func setUp() {
        super.setUp()
        encryptionPassword = CurrentValueSubject<String, Never>("")
        isEditingEncryptionPassword = CurrentValueSubject<Bool, Never>(false)
        revealTrigger = PassthroughSubject<Void, Never>()
        fakeController = FakeInputFromController()
        mockWallet = MockWalletUseCase()
        wallet = TestWalletFactory.makeWallet()
        Container.shared.extractKeyPairUseCase.register { [unowned self] in mockWallet }
    }

    override func tearDown() {
        cancellables.removeAll()
        Container.shared.manager.reset()
        wallet = nil
        mockWallet = nil
        fakeController = nil
        revealTrigger = nil
        isEditingEncryptionPassword = nil
        encryptionPassword = nil
        super.tearDown()
    }

    func test_rightBarButton_emitsDismiss() {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var observed: DecryptKeystoreToRevealKeyPairUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        fakeController.rightBarButtonTriggerSubject.send(())

        guard case .dismiss = observed else {
            return XCTFail("Expected .dismiss, got \(String(describing: observed))")
        }
    }

    func test_isRevealButtonEnabled_requiresValidPassword() {
        let sut = makeSUT()
        let output = sut.transform(input: makeInput())
        var states: [Bool] = []
        output.isRevealButtonEnabled.sink { states.append($0) }.store(in: &cancellables)

        encryptionPassword.send("short")
        encryptionPassword.send(TestWalletFactory.testPassword)

        XCTAssertEqual(states.last, true)
    }

    func test_revealTrigger_withValidPassword_callsExtractAndEmitsKeyPair() {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var observed: DecryptKeystoreToRevealKeyPairUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        encryptionPassword.send(TestWalletFactory.testPassword)
        revealTrigger.send(())

        XCTAssertEqual(mockWallet.extractKeyPairCallCount, 1)
        guard case .decryptKeystoreReavealing = observed else {
            return XCTFail("Expected .decryptKeystoreReavealing, got \(String(describing: observed))")
        }
    }

    private func makeSUT() -> DecryptKeystoreToRevealKeyPairViewModel {
        DecryptKeystoreToRevealKeyPairViewModel(wallet: Just(wallet).eraseToAnyPublisher())
    }

    private func makeInput() -> DecryptKeystoreToRevealKeyPairViewModel.Input {
        DecryptKeystoreToRevealKeyPairViewModel.Input(
            fromView: .init(
                encryptionPassword: encryptionPassword.eraseToAnyPublisher(),
                isEditingEncryptionPassword: isEditingEncryptionPassword.eraseToAnyPublisher(),
                revealTrigger: revealTrigger.eraseToAnyPublisher()
            ),
            fromController: fakeController.makeInput()
        )
    }
}
