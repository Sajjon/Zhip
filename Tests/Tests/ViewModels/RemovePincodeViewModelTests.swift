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
import SingleLineControllerController
@testable import Zhip

/// Tests for `RemovePincodeViewModel`.
///
/// Covers the cancel path (left bar button → `.cancelPincodeRemoval`) and the
/// correct-pincode path (entering the existing pin → `.removePincode` and use case
/// cleanup).
final class RemovePincodeViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var pincodeInput: CurrentValueSubject<Pincode?, Never>!
    private var fakeController: FakeInputFromController!
    private var mockUseCase: MockPincodeUseCase!
    private var existingPin: Pincode!

    override func setUpWithError() throws {
        try super.setUpWithError()
        existingPin = try Pincode(digits: [.one, .two, .three, .four])
        pincodeInput = CurrentValueSubject<Pincode?, Never>(nil)
        fakeController = FakeInputFromController()
        mockUseCase = MockPincodeUseCase(pincode: existingPin)
    }

    override func tearDown() {
        cancellables.removeAll()
        mockUseCase = nil
        fakeController = nil
        pincodeInput = nil
        existingPin = nil
        super.tearDown()
    }

    func test_leftBarButton_emitsCancelPincodeRemoval() {
        let sut = makeSUT()
        var observed: RemovePincodeUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        fakeController.leftBarButtonTriggerSubject.send(())

        guard case .cancelPincodeRemoval = observed else {
            return XCTFail("Expected .cancelPincodeRemoval, got \(String(describing: observed))")
        }
    }

    func test_correctPincodeEntered_deletesPincodeAndEmitsRemovePincode() {
        let sut = makeSUT()
        var observed: RemovePincodeUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        pincodeInput.send(existingPin)

        XCTAssertEqual(mockUseCase.deletePincodeCallCount, 1)
        guard case .removePincode = observed else {
            return XCTFail("Expected .removePincode, got \(String(describing: observed))")
        }
    }

    func test_wrongPincodeEntered_doesNotRemove() throws {
        let sut = makeSUT()
        var observed: RemovePincodeUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        let wrongPin = try Pincode(digits: [.nine, .nine, .nine, .nine])
        pincodeInput.send(wrongPin)

        XCTAssertEqual(mockUseCase.deletePincodeCallCount, 0)
        XCTAssertNil(observed)
    }

    private func makeSUT() -> RemovePincodeViewModel {
        let sut = RemovePincodeViewModel(useCase: mockUseCase)
        let input = RemovePincodeViewModel.Input(
            fromView: .init(pincode: pincodeInput.eraseToAnyPublisher()),
            fromController: fakeController.makeInput()
        )
        _ = sut.transform(input: input)
        return sut
    }
}
