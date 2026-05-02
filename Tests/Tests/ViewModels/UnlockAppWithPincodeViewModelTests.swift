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
import Validation
import XCTest

/// Tests for `UnlockAppWithPincodeViewModel`.
///
/// Covers the pincode-validation gate that drives `.unlockApp`, the
/// validation publisher that downstream views bind to, and the biometric
/// `viewDidAppear` branch through the injected `BiometricsAuthenticator`
/// protocol (real `LAContext` is replaced with a mock so no system prompt
/// fires in tests).
final class UnlockAppWithPincodeViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var pincodeSubject: CurrentValueSubject<Pincode?, Never>!
    private var fakeController: FakeInputFromController!
    private var mockPincode: MockPincodeUseCase!
    private var mockBiometrics: MockBiometricsAuthenticator!
    private var existingPincode: Pincode!

    override func setUpWithError() throws {
        try super.setUpWithError()
        existingPincode = try Pincode(digits: [.one, .two, .three, .four])
        pincodeSubject = CurrentValueSubject<Pincode?, Never>(nil)
        fakeController = FakeInputFromController()
        mockPincode = MockPincodeUseCase()
        mockPincode.pincode = existingPincode
        mockBiometrics = MockBiometricsAuthenticator()
        Container.shared.pincodeUseCase.register { [unowned self] in mockPincode }
        Container.shared.biometricsAuthenticator.register { [unowned self] in mockBiometrics }
    }

    override func tearDown() {
        cancellables.removeAll()
        Container.shared.manager.reset()
        mockBiometrics = nil
        mockPincode = nil
        fakeController = nil
        pincodeSubject = nil
        existingPincode = nil
        super.tearDown()
    }

    func test_correctPincode_emitsUnlockApp() {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var observed: UnlockAppWithPincodeUserAction?
        let expectation = expectation(description: "unlockApp emitted")
        sut.navigator.navigation.sink {
            observed = $0
            expectation.fulfill()
        }.store(in: &cancellables)

        pincodeSubject.send(existingPincode)

        wait(for: [expectation], timeout: 1.0)
        guard case .unlockApp = observed else {
            return XCTFail("Expected .unlockApp, got \(String(describing: observed))")
        }
    }

    func test_incorrectPincode_doesNotEmitUnlockApp() throws {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var observed: UnlockAppWithPincodeUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        let wrong = try Pincode(digits: [.nine, .nine, .nine, .nine])
        pincodeSubject.send(wrong)

        XCTAssertNil(observed)
    }

    func test_pincodeValidation_emitsErrorForWrongPincode() throws {
        let sut = makeSUT()
        let output = sut.transform(input: makeInput())
        var validations: [AnyValidation] = []
        output.pincodeValidation.sink { validations.append($0) }.store(in: &cancellables)

        let wrong = try Pincode(digits: [.zero, .zero, .zero, .zero])
        pincodeSubject.send(wrong)

        XCTAssertTrue(validations.contains { $0.isError })
    }

    func test_pincodeValidation_emitsValidForCorrectPincode() {
        let sut = makeSUT()
        let output = sut.transform(input: makeInput())
        var validations: [AnyValidation] = []
        output.pincodeValidation.sink { validations.append($0) }.store(in: &cancellables)

        pincodeSubject.send(existingPincode)

        XCTAssertTrue(validations.contains { if case .valid = $0 { true } else { false } })
    }

    // MARK: - Biometrics

    func test_viewDidAppear_triggersBiometricsAuthenticator() {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())

        fakeController.viewDidAppearSubject.send(())

        XCTAssertEqual(mockBiometrics.authenticateCallCount, 1)
    }

    func test_biometricsSuccess_emitsUnlockApp() {
        mockBiometrics.result = true
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        let expectation = expectation(description: "unlockApp emitted")
        var observed: UnlockAppWithPincodeUserAction?
        sut.navigator.navigation.sink {
            observed = $0
            expectation.fulfill()
        }.store(in: &cancellables)

        fakeController.viewDidAppearSubject.send(())

        wait(for: [expectation], timeout: 1.0)
        guard case .unlockApp = observed else {
            return XCTFail("Expected .unlockApp, got \(String(describing: observed))")
        }
    }

    func test_biometricsFailure_doesNotEmitUnlockApp() {
        mockBiometrics.result = false
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var observed: UnlockAppWithPincodeUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        fakeController.viewDidAppearSubject.send(())
        let expectation = expectation(description: "drain")
        DispatchQueue.main.async { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertNil(observed)
    }

    private func makeSUT() -> UnlockAppWithPincodeViewModel {
        UnlockAppWithPincodeViewModel()
    }

    private func makeInput() -> UnlockAppWithPincodeViewModel.Input {
        UnlockAppWithPincodeViewModel.Input(
            fromView: .init(pincode: pincodeSubject.eraseToAnyPublisher()),
            fromController: fakeController.makeInput()
        )
    }
}
