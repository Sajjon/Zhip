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
import NanoViewControllerController
import XCTest
import Zesame

/// Tests for `SignTransactionViewModel`.
///
/// Verifies the password-validation gate on the sign button, that signing
/// triggers `SendTransactionUseCase` with the supplied payment, and that the
/// resulting `TransactionResponse` is propagated as `.sign`.
@MainActor
final class SignTransactionViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var encryptionPassword: CurrentValueSubject<String, Never>!
    private var isEditingEncryptionPassword: CurrentValueSubject<Bool, Never>!
    private var signAndSendTrigger: PassthroughSubject<Void, Never>!
    private var fakeController: FakeInputFromController!
    private var mockTransactions: MockTransactionsUseCase!
    private var mockWallet: MockWalletUseCase!
    private var payment: Payment!

    override func setUpWithError() throws {
        try super.setUpWithError()
        encryptionPassword = CurrentValueSubject<String, Never>("")
        isEditingEncryptionPassword = CurrentValueSubject<Bool, Never>(false)
        signAndSendTrigger = PassthroughSubject<Void, Never>()
        fakeController = FakeInputFromController()
        mockTransactions = MockTransactionsUseCase()
        mockWallet = MockWalletUseCase()
        mockWallet.storedWallet = TestWalletFactory.makeWallet()

        let address = try LegacyAddress(string: "e3090a1309DfAC40352d03dEc6cCD9cAd213e76B")
        payment = try Payment(
            to: address,
            amount: Amount(zil: 1),
            gasPrice: GasPrice(li: 1_000_000)
        )

        Container.shared.sendTransactionUseCase.register { [unowned self] in MainActor.assumeIsolated { mockTransactions } }
        Container.shared.walletStorageUseCase.register { [unowned self] in MainActor.assumeIsolated { mockWallet } }
        Container.shared.verifyEncryptionPasswordUseCase.register { [unowned self] in MainActor.assumeIsolated { mockWallet } }
    }

    override func tearDown() {
        cancellables.removeAll()
        Container.shared.manager.reset()
        payment = nil
        mockWallet = nil
        mockTransactions = nil
        fakeController = nil
        signAndSendTrigger = nil
        isEditingEncryptionPassword = nil
        encryptionPassword = nil
        super.tearDown()
    }

    func test_isSignButtonEnabled_requiresValidPassword() {
        let sut = makeSUT()
        let output = sut.transform(input: makeInput())
        var states: [Bool] = []
        output.isSignButtonEnabled.sink { states.append($0) }.store(in: &cancellables)

        encryptionPassword.send(TestWalletFactory.testPassword)
        isEditingEncryptionPassword.send(false)
        // SignTransactionViewModel.isPasswordVerified debounces 250ms before
        // hitting the verify use case — pump the runloop past the debounce
        // so the mock fires and combineLatest emits the final true.
        drainRunLoop(seconds: 0.4)

        XCTAssertEqual(states.last, true)
    }

    func test_signTrigger_callsSendTransactionWithPayment() throws {
        let json = """
        {"TranID":"abc123","Info":"Sent"}
        """
        let response = try JSONDecoder().decode(TransactionResponse.self, from: Data(json.utf8))
        mockTransactions.sendTransactionResult = .success(response)

        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var observed: SignTransactionUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        encryptionPassword.send(TestWalletFactory.testPassword)
        signAndSendTrigger.send(())

        XCTAssertEqual(mockTransactions.sendTransactionCallCount, 1)
        XCTAssertEqual(mockTransactions.lastSendTransactionPayment?.amount, payment.amount)
        guard case let .sign(emitted) = observed else {
            return XCTFail("Expected .sign, got \(String(describing: observed))")
        }
        XCTAssertEqual(emitted.transactionIdentifier, "abc123")
    }

    private func makeSUT() -> SignTransactionViewModel {
        SignTransactionViewModel(paymentToSign: payment)
    }

    private func makeInput() -> SignTransactionViewModel.Input {
        SignTransactionViewModel.Input(
            fromView: .init(
                encryptionPassword: encryptionPassword.eraseToAnyPublisher(),
                isEditingEncryptionPassword: isEditingEncryptionPassword.eraseToAnyPublisher(),
                signAndSendTrigger: signAndSendTrigger.eraseToAnyPublisher()
            ),
            fromController: fakeController.makeInput()
        )
    }
}
