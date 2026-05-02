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
import NanoViewControllerController
import XCTest

/// Tests for `AskForCrashReportingPermissionsViewModel`.
///
/// Verifies the ViewModel forwards accept/decline to the use case with the correct
/// boolean and emits the `.answerQuestionAboutCrashReporting` navigation step.
final class AskForCrashReportingPermissionsViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var useCase: MockOnboardingUseCase!
    private var isHaveRead: PassthroughSubject<Bool, Never>!
    private var acceptTrigger: PassthroughSubject<Void, Never>!
    private var declineTrigger: PassthroughSubject<Void, Never>!
    private var fakeController: FakeInputFromController!

    override func setUp() {
        super.setUp()
        useCase = MockOnboardingUseCase()
        isHaveRead = PassthroughSubject<Bool, Never>()
        acceptTrigger = PassthroughSubject<Void, Never>()
        declineTrigger = PassthroughSubject<Void, Never>()
        fakeController = FakeInputFromController()
    }

    override func tearDown() {
        cancellables.removeAll()
        fakeController = nil
        declineTrigger = nil
        acceptTrigger = nil
        isHaveRead = nil
        useCase = nil
        super.tearDown()
    }

    // MARK: - accept

    func test_acceptTrigger_passesTrueToUseCaseAndNavigates() {
        // Arrange
        let sut = makeSUT(isDismissible: false)
        var observed: AskForCrashReportingPermissionsNavigation?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        // Act
        acceptTrigger.send(())

        // Assert
        XCTAssertEqual(useCase.lastAnsweredCrashReportingValue, true)
        guard case .answerQuestionAboutCrashReporting = observed else {
            return XCTFail("Expected .answerQuestionAboutCrashReporting, got \(String(describing: observed))")
        }
    }

    // MARK: - decline

    func test_declineTrigger_passesFalseToUseCaseAndNavigates() {
        // Arrange
        let sut = makeSUT(isDismissible: false)

        // Act
        declineTrigger.send(())

        // Assert
        XCTAssertEqual(useCase.lastAnsweredCrashReportingValue, false)
    }

    // MARK: - Helpers

    private func makeSUT(isDismissible: Bool) -> AskForCrashReportingPermissionsViewModel {
        let sut = AskForCrashReportingPermissionsViewModel(useCase: useCase, isDismissible: isDismissible)
        let input = AskForCrashReportingPermissionsViewModel.Input(
            fromView: .init(
                isHaveReadDisclaimerCheckboxChecked: isHaveRead.eraseToAnyPublisher(),
                acceptTrigger: acceptTrigger.eraseToAnyPublisher(),
                declineTrigger: declineTrigger.eraseToAnyPublisher()
            ),
            fromController: fakeController.makeInput()
        )
        _ = sut.transform(input: input)
        return sut
    }
}
