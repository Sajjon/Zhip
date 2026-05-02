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

/// Tests for `CreateNewWalletViewModel`.
///
/// Drives the three gating signals (new password, confirmed password, checkbox)
/// through `CurrentValueSubject`s and asserts the continue-button enabled state
/// and the `.createWallet` / `.cancel` navigation steps.
final class CreateNewWalletViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var newPassword: CurrentValueSubject<String, Never>!
    private var isEditingNewPassword: CurrentValueSubject<Bool, Never>!
    private var confirmedPassword: CurrentValueSubject<String, Never>!
    private var isEditingConfirmedPassword: CurrentValueSubject<Bool, Never>!
    private var isBackedUp: CurrentValueSubject<Bool, Never>!
    private var createTrigger: PassthroughSubject<Void, Never>!
    private var fakeController: FakeInputFromController!
    private var mockWallet: MockWalletUseCase!

    override func setUp() {
        super.setUp()
        newPassword = CurrentValueSubject<String, Never>("")
        isEditingNewPassword = CurrentValueSubject<Bool, Never>(false)
        confirmedPassword = CurrentValueSubject<String, Never>("")
        isEditingConfirmedPassword = CurrentValueSubject<Bool, Never>(false)
        isBackedUp = CurrentValueSubject<Bool, Never>(false)
        createTrigger = PassthroughSubject<Void, Never>()
        fakeController = FakeInputFromController()
        mockWallet = MockWalletUseCase()
        Container.shared.createWalletUseCase.register { [unowned self] in mockWallet }
    }

    override func tearDown() {
        cancellables.removeAll()
        Container.shared.manager.reset()
        mockWallet = nil
        fakeController = nil
        createTrigger = nil
        isBackedUp = nil
        isEditingConfirmedPassword = nil
        confirmedPassword = nil
        isEditingNewPassword = nil
        newPassword = nil
        super.tearDown()
    }

    // MARK: - isContinueButtonEnabled

    func test_continueButtonEnabled_requiresValidPasswordAndBackupCheckbox() {
        let sut = makeSUT()
        var isEnabledEvents: [Bool] = []
        let output = sut.transform(input: makeInput())
        output.isContinueButtonEnabled.sink { isEnabledEvents.append($0) }.store(in: &cancellables)

        // Passwords match and meet the minimum length, but backup not checked yet.
        newPassword.send("apabanan123")
        confirmedPassword.send("apabanan123")
        XCTAssertEqual(isEnabledEvents.last, false)

        // Checking the backup box flips the gate to enabled.
        isBackedUp.send(true)
        XCTAssertEqual(isEnabledEvents.last, true)
    }

    func test_continueButtonEnabled_mismatchedPasswords_disablesButton() {
        let sut = makeSUT()
        var isEnabledEvents: [Bool] = []
        let output = sut.transform(input: makeInput())
        output.isContinueButtonEnabled.sink { isEnabledEvents.append($0) }.store(in: &cancellables)

        newPassword.send("apabanan123")
        confirmedPassword.send("different!")
        isBackedUp.send(true)

        XCTAssertEqual(isEnabledEvents.last, false)
    }

    // MARK: - Navigation

    func test_createWalletTrigger_withValidPassword_callsUseCaseAndEmitsCreateWallet() {
        let sut = makeSUT()
        var observed: CreateNewWalletUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        newPassword.send("apabanan123")
        confirmedPassword.send("apabanan123")
        isBackedUp.send(true)
        createTrigger.send(())

        XCTAssertEqual(mockWallet.createNewWalletCallCount, 1)
        XCTAssertEqual(mockWallet.lastCreateEncryptionPassword, "apabanan123")
        guard case .createWallet = observed else {
            return XCTFail("Expected .createWallet, got \(String(describing: observed))")
        }
    }

    func test_leftBarButton_emitsCancel() {
        let sut = makeSUT()
        var observed: CreateNewWalletUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        fakeController.leftBarButtonTriggerSubject.send(())

        guard case .cancel = observed else {
            return XCTFail("Expected .cancel, got \(String(describing: observed))")
        }
    }

    // MARK: - Helpers

    private func makeSUT() -> CreateNewWalletViewModel {
        let sut = CreateNewWalletViewModel()
        _ = sut.transform(input: makeInput())
        return sut
    }

    private func makeInput() -> CreateNewWalletViewModel.Input {
        CreateNewWalletViewModel.Input(
            fromView: .init(
                newEncryptionPassword: newPassword.eraseToAnyPublisher(),
                isEditingNewEncryptionPassword: isEditingNewPassword.eraseToAnyPublisher(),
                confirmedNewEncryptionPassword: confirmedPassword.eraseToAnyPublisher(),
                isEditingConfirmedEncryptionPassword: isEditingConfirmedPassword.eraseToAnyPublisher(),
                isHaveBackedUpPasswordCheckboxChecked: isBackedUp.eraseToAnyPublisher(),
                createWalletTrigger: createTrigger.eraseToAnyPublisher()
            ),
            fromController: fakeController.makeInput()
        )
    }
}
