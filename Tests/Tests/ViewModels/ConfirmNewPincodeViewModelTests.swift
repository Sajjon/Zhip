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

@testable import AppFeature
import Combine
import NanoViewControllerController
import XCTest

/// Tests for `ConfirmNewPincodeViewModel`.
///
/// Covers the confirmation path (matching pincode → `.confirmPincode` + persist) and
/// the skip path (right bar button → `.skip`).
@MainActor
final class ConfirmNewPincodeViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var pincodeInput: CurrentValueSubject<Pincode?, Never>!
    private var isBackedUpSubject: CurrentValueSubject<Bool, Never>!
    private var confirmedTrigger: PassthroughSubject<Void, Never>!
    private var fakeController: FakeInputFromController!
    private var mockUseCase: MockPincodeUseCase!
    private var unconfirmed: Pincode!

    override func setUpWithError() throws {
        try super.setUpWithError()
        unconfirmed = try Pincode(digits: [.one, .two, .three, .four])
        pincodeInput = CurrentValueSubject<Pincode?, Never>(nil)
        isBackedUpSubject = CurrentValueSubject<Bool, Never>(false)
        confirmedTrigger = PassthroughSubject<Void, Never>()
        fakeController = FakeInputFromController()
        mockUseCase = MockPincodeUseCase()
    }

    override func tearDown() {
        cancellables.removeAll()
        mockUseCase = nil
        fakeController = nil
        confirmedTrigger = nil
        isBackedUpSubject = nil
        pincodeInput = nil
        unconfirmed = nil
        super.tearDown()
    }

    func test_matchingPincodeAndBackedUp_confirms() {
        let sut = makeSUT()
        var observed: ConfirmNewPincodeUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        pincodeInput.send(unconfirmed)
        isBackedUpSubject.send(true)
        confirmedTrigger.send(())

        XCTAssertEqual(mockUseCase.userChosePincodeCallCount, 1)
        XCTAssertEqual(mockUseCase.pincode, unconfirmed)
        guard case .confirmPincode = observed else {
            return XCTFail("Expected .confirmPincode, got \(String(describing: observed))")
        }
    }

    func test_mismatchedPincode_doesNotConfirm() throws {
        let sut = makeSUT()
        var observed: ConfirmNewPincodeUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        let wrong = try Pincode(digits: [.nine, .nine, .nine, .nine])
        pincodeInput.send(wrong)
        confirmedTrigger.send(())

        XCTAssertEqual(mockUseCase.userChosePincodeCallCount, 0)
        XCTAssertNil(observed)
    }

    func test_rightBarButton_emitsSkip() {
        let sut = makeSUT()
        var observed: ConfirmNewPincodeUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        fakeController.rightBarButtonTriggerSubject.send(())

        guard case .skip = observed else {
            return XCTFail("Expected .skip, got \(String(describing: observed))")
        }
    }

    func test_isConfirmEnabled_requiresBothPincodeAndBackedUp() {
        let sut = makeSUT()
        var isEnabled: [Bool] = []
        let output = sut.transform(input: ConfirmNewPincodeViewModel.Input(
            fromView: .init(
                pincode: pincodeInput.eraseToAnyPublisher(),
                isHaveBackedUpPincodeCheckboxChecked: isBackedUpSubject.eraseToAnyPublisher(),
                confirmedTrigger: confirmedTrigger.eraseToAnyPublisher()
            ),
            fromController: fakeController.makeInput()
        ))
        output.publishers.isConfirmPincodeEnabled.sink { isEnabled.append($0) }.store(in: &cancellables)

        pincodeInput.send(unconfirmed)
        isBackedUpSubject.send(false)

        XCTAssertFalse(isEnabled.contains(true), "Should be disabled without backup check")

        isBackedUpSubject.send(true)

        XCTAssertTrue(isEnabled.contains(true), "Should become enabled once pin matches and backup is checked")
    }

    private func makeSUT() -> ConfirmNewPincodeViewModel {
        let sut = ConfirmNewPincodeViewModel(useCase: mockUseCase, confirm: unconfirmed)
        let input = ConfirmNewPincodeViewModel.Input(
            fromView: .init(
                pincode: pincodeInput.eraseToAnyPublisher(),
                isHaveBackedUpPincodeCheckboxChecked: isBackedUpSubject.eraseToAnyPublisher(),
                confirmedTrigger: confirmedTrigger.eraseToAnyPublisher()
            ),
            fromController: fakeController.makeInput()
        )
        _ = sut.transform(input: input)
        return sut
    }
}
