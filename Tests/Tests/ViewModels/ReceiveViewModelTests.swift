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
import SingleLineControllerController
import XCTest

/// Tests for `ReceiveViewModel`.
///
/// Exercises the share path (share trigger → `.requestTransaction`) and the finish
/// path (right bar → `.finish`). The wallet is preloaded via `MockWalletUseCase`'s
/// `storedWallet`.
final class ReceiveViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var mockWallet: MockWalletUseCase!
    private var mockPasteboard: MockPasteboard!
    private var amountSubject: PassthroughSubject<String, Never>!
    private var didEndEditing: PassthroughSubject<Void, Never>!
    private var copySubject: PassthroughSubject<Void, Never>!
    private var shareSubject: PassthroughSubject<Void, Never>!
    private var fakeController: FakeInputFromController!

    override func setUp() {
        super.setUp()
        mockWallet = MockWalletUseCase()
        mockWallet.storedWallet = TestWalletFactory.makeWallet()
        Container.shared.walletStorageUseCase.register { [unowned self] in mockWallet }
        mockPasteboard = MockPasteboard()
        Container.shared.pasteboard.register { [unowned self] in mockPasteboard }
        amountSubject = PassthroughSubject<String, Never>()
        didEndEditing = PassthroughSubject<Void, Never>()
        copySubject = PassthroughSubject<Void, Never>()
        shareSubject = PassthroughSubject<Void, Never>()
        fakeController = FakeInputFromController()
    }

    override func tearDown() {
        cancellables.removeAll()
        Container.shared.manager.reset()
        fakeController = nil
        shareSubject = nil
        copySubject = nil
        didEndEditing = nil
        amountSubject = nil
        mockPasteboard = nil
        mockWallet = nil
        super.tearDown()
    }

    func test_rightBarButton_emitsFinish() {
        let sut = makeSUT()
        var observed: ReceiveUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        fakeController.rightBarButtonTriggerSubject.send(())

        guard case .finish = observed else {
            return XCTFail("Expected .finish, got \(String(describing: observed))")
        }
    }

    func test_shareTrigger_emitsRequestTransaction() {
        let sut = makeSUT()
        var observed: ReceiveUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        // Zero-amount transaction is always valid — just trigger a share.
        shareSubject.send(())

        guard case .requestTransaction = observed else {
            return XCTFail("Expected .requestTransaction, got \(String(describing: observed))")
        }
    }

    func test_receivingAddress_matchesWalletAddress() {
        let sut = makeSUT()
        var receivedAddress: String?
        let output = sut.transform(input: makeInput())
        output.receivingAddress.sink { receivedAddress = $0 }.store(in: &cancellables)

        XCTAssertEqual(receivedAddress, mockWallet.storedWallet?.bech32Address.asString)
    }

    func test_copyMyAddressTrigger_copiesAddressAndEmitsToast() {
        _ = makeSUT()
        var emittedToast: Toast?
        fakeController.toastSubject.sink { emittedToast = $0 }.store(in: &cancellables)

        copySubject.send(())

        XCTAssertEqual(mockPasteboard.copiedString, mockWallet.storedWallet?.bech32Address.asString)
        XCTAssertNotNil(emittedToast)
    }

    private func makeSUT() -> ReceiveViewModel {
        let sut = ReceiveViewModel()
        _ = sut.transform(input: makeInput())
        return sut
    }

    private func makeInput() -> ReceiveViewModel.Input {
        ReceiveViewModel.Input(
            fromView: .init(
                qrCodeImageHeight: 200,
                amountToReceive: amountSubject.eraseToAnyPublisher(),
                didEndEditingAmount: didEndEditing.eraseToAnyPublisher(),
                copyMyAddressTrigger: copySubject.eraseToAnyPublisher(),
                shareTrigger: shareSubject.eraseToAnyPublisher()
            ),
            fromController: fakeController.makeInput()
        )
    }
}
