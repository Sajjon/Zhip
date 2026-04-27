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
import XCTest
@testable import Zhip

/// Tests for `ConfirmWalletRemovalViewModel`.
///
/// Verifies the cancel-vs-confirm navigation branches and that the confirm
/// button is gated on the "I've backed up my wallet" checkbox.
final class ConfirmWalletRemovalViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var confirmTrigger: PassthroughSubject<Void, Never>!
    private var isBackedUp: CurrentValueSubject<Bool, Never>!
    private var fakeController: FakeInputFromController!

    override func setUp() {
        super.setUp()
        confirmTrigger = PassthroughSubject<Void, Never>()
        isBackedUp = CurrentValueSubject<Bool, Never>(false)
        fakeController = FakeInputFromController()
    }

    override func tearDown() {
        cancellables.removeAll()
        fakeController = nil
        isBackedUp = nil
        confirmTrigger = nil
        super.tearDown()
    }

    func test_leftBarButton_emitsCancel() {
        let sut = makeSUT()
        var observed: ConfirmWalletRemovalUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        fakeController.leftBarButtonTriggerSubject.send(())

        guard case .cancel = observed else {
            return XCTFail("Expected .cancel, got \(String(describing: observed))")
        }
    }

    func test_confirmTrigger_emitsConfirm() {
        let sut = makeSUT()
        var observed: ConfirmWalletRemovalUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        confirmTrigger.send(())

        guard case .confirm = observed else {
            return XCTFail("Expected .confirm, got \(String(describing: observed))")
        }
    }

    func test_isConfirmButtonEnabled_mirrorsCheckboxState() {
        let sut = ConfirmWalletRemovalViewModel()
        let output = sut.transform(input: makeInput())
        var events: [Bool] = []
        output.isConfirmButtonEnabled.sink { events.append($0) }.store(in: &cancellables)

        isBackedUp.send(true)
        isBackedUp.send(false)

        XCTAssertEqual(events, [false, true, false])
    }

    private func makeSUT() -> ConfirmWalletRemovalViewModel {
        let sut = ConfirmWalletRemovalViewModel()
        _ = sut.transform(input: makeInput())
        return sut
    }

    private func makeInput() -> ConfirmWalletRemovalViewModel.Input {
        ConfirmWalletRemovalViewModel.Input(
            fromView: .init(
                confirmTrigger: confirmTrigger.eraseToAnyPublisher(),
                isWalletBackedUpCheckboxChecked: isBackedUp.eraseToAnyPublisher()
            ),
            fromController: fakeController.makeInput()
        )
    }
}
