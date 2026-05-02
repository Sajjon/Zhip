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
import SingleLineControllerController
import XCTest

/// Tests for `TermsOfServiceViewModel`.
///
/// We inject a hand-rolled `MockOnboardingUseCase` so we can verify the ViewModel
/// calls `didAcceptTermsOfService()` exactly once when the user accepts, and emits
/// the right `.acceptTermsOfService` / `.dismiss` navigation steps.
final class TermsOfServiceViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var useCase: MockOnboardingUseCase!
    private var didScrollToBottom: PassthroughSubject<Void, Never>!
    private var didAcceptTerms: PassthroughSubject<Void, Never>!
    private var fakeController: FakeInputFromController!

    override func setUp() {
        super.setUp()
        useCase = MockOnboardingUseCase()
        didScrollToBottom = PassthroughSubject<Void, Never>()
        didAcceptTerms = PassthroughSubject<Void, Never>()
        fakeController = FakeInputFromController()
    }

    override func tearDown() {
        cancellables.removeAll()
        fakeController = nil
        didAcceptTerms = nil
        didScrollToBottom = nil
        useCase = nil
        super.tearDown()
    }

    // MARK: - accept path

    func test_didAcceptTerms_callsUseCaseAndEmitsAccept() {
        // Arrange
        let sut = makeSUT(isDismissible: false)
        var observed: TermsOfServiceNavigation?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        // Act
        didAcceptTerms.send(())

        // Assert
        XCTAssertEqual(useCase.didAcceptTermsOfServiceCallCount, 1)
        guard case .acceptTermsOfService = observed else {
            return XCTFail("Expected .acceptTermsOfService, got \(String(describing: observed))")
        }
    }

    // MARK: - dismissable path

    func test_rightBarButton_emitsDismiss_whenDismissible() {
        // Arrange
        let sut = makeSUT(isDismissible: true)
        var observed: TermsOfServiceNavigation?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        // Act
        fakeController.rightBarButtonTriggerSubject.send(())

        // Assert
        guard case .dismiss = observed else {
            return XCTFail("Expected .dismiss, got \(String(describing: observed))")
        }
    }

    func test_rightBarButton_isIgnored_whenNotDismissible() {
        // Arrange
        let sut = makeSUT(isDismissible: false)
        var observed: TermsOfServiceNavigation?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        // Act
        fakeController.rightBarButtonTriggerSubject.send(())

        // Assert
        XCTAssertNil(observed)
    }

    // MARK: - Helpers

    private func makeSUT(isDismissible: Bool) -> TermsOfServiceViewModel {
        let sut = TermsOfServiceViewModel(useCase: useCase, isDismissible: isDismissible)
        let input = TermsOfServiceViewModel.Input(
            fromView: .init(
                didScrollToBottom: didScrollToBottom.eraseToAnyPublisher(),
                didAcceptTerms: didAcceptTerms.eraseToAnyPublisher()
            ),
            fromController: fakeController.makeInput()
        )
        _ = sut.transform(input: input)
        return sut
    }
}
