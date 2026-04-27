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
@testable import Zhip

/// Tests for `BackUpKeystoreViewModel`.
///
/// Covers the keystore-as-JSON output, copy-to-pasteboard side effect with toast,
/// and the right-bar-button → `.finished` navigation branch.
final class BackUpKeystoreViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var copyTrigger: PassthroughSubject<Void, Never>!
    private var fakeController: FakeInputFromController!
    private var wallet: Zhip.Wallet!
    private var mockPasteboard: MockPasteboard!

    override func setUp() {
        super.setUp()
        copyTrigger = PassthroughSubject<Void, Never>()
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
        copyTrigger = nil
        super.tearDown()
    }

    func test_output_emitsPrettyPrintedKeystoreJSON() {
        let sut = makeSUT()
        let output = sut.transform(input: makeInput())
        var lastKeystore: String?
        output.keystore.sink { lastKeystore = $0 }.store(in: &cancellables)

        XCTAssertNotNil(lastKeystore)
        XCTAssertTrue(lastKeystore?.contains("\"version\"") == true)
    }

    func test_copyTrigger_writesKeystoreToPasteboardAndSendsToast() {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var toasts: [Toast] = []
        fakeController.toastSubject.sink { toasts.append($0) }.store(in: &cancellables)

        copyTrigger.send(())

        XCTAssertEqual(toasts.count, 1)
        let pasted = mockPasteboard.copiedString ?? ""
        XCTAssertTrue(pasted.contains(wallet.keystore.address.asString))
        XCTAssertTrue(pasted.contains("\"version\""))
    }

    func test_rightBarButton_emitsFinished() {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var observed: BackUpKeystoreUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        fakeController.rightBarButtonTriggerSubject.send(())

        guard case .finished = observed else {
            return XCTFail("Expected .finished, got \(String(describing: observed))")
        }
    }

    private func makeSUT() -> BackUpKeystoreViewModel {
        BackUpKeystoreViewModel(wallet: Just(wallet).eraseToAnyPublisher())
    }

    private func makeInput() -> BackUpKeystoreViewModel.Input {
        BackUpKeystoreViewModel.Input(
            fromView: .init(copyTrigger: copyTrigger.eraseToAnyPublisher()),
            fromController: fakeController.makeInput()
        )
    }
}
