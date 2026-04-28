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

/// Tests for `ChoosePincodeViewModel`.
///
/// Covers the "Done" path (forwards the pincode) and the "Skip" path
/// (emits `.skip` from the nav bar right trigger).
final class ChoosePincodeViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var pincodeInput: CurrentValueSubject<Pincode?, Never>!
    private var doneTrigger: PassthroughSubject<Void, Never>!
    private var fakeController: FakeInputFromController!

    override func setUp() {
        super.setUp()
        pincodeInput = CurrentValueSubject<Pincode?, Never>(nil)
        doneTrigger = PassthroughSubject<Void, Never>()
        fakeController = FakeInputFromController()
    }

    override func tearDown() {
        cancellables.removeAll()
        fakeController = nil
        doneTrigger = nil
        pincodeInput = nil
        super.tearDown()
    }

    func test_doneTrigger_withEnteredPincode_emitsChosePincode() throws {
        // Arrange
        let pin = try Pincode(digits: [.one, .two, .three, .four])
        let sut = makeSUT()
        var observed: ChoosePincodeUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)
        pincodeInput.send(pin)

        // Act
        doneTrigger.send(())

        // Assert
        guard case let .chosePincode(captured) = observed else {
            return XCTFail("Expected .chosePincode, got \(String(describing: observed))")
        }
        XCTAssertEqual(captured, pin)
    }

    func test_rightBarButton_emitsSkip() {
        // Arrange
        let sut = makeSUT()
        var observed: ChoosePincodeUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        // Act
        fakeController.rightBarButtonTriggerSubject.send(())

        // Assert
        guard case .skip = observed else {
            return XCTFail("Expected .skip, got \(String(describing: observed))")
        }
    }

    private func makeSUT() -> ChoosePincodeViewModel {
        let sut = ChoosePincodeViewModel()
        let input = ChoosePincodeViewModel.Input(
            fromView: .init(
                pincode: pincodeInput.eraseToAnyPublisher(),
                doneTrigger: doneTrigger.eraseToAnyPublisher()
            ),
            fromController: fakeController.makeInput()
        )
        _ = sut.transform(input: input)
        return sut
    }
}
