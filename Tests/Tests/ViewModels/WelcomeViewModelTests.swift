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

/// Tests for the (tiny) `WelcomeViewModel`.
///
/// The ViewModel has no dependencies and one responsibility: forward the
/// `startTrigger` to `navigator.next(.start)`. The test drives the input subject
/// and asserts that the navigator emits the expected step.
final class WelcomeViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func test_startTrigger_emitsStartNavigationStep() {
        // Arrange
        let sut = WelcomeViewModel()
        let startTrigger = PassthroughSubject<Void, Never>()
        let input = WelcomeViewModel.Input(
            fromView: .init(startTrigger: startTrigger.eraseToAnyPublisher()),
            fromController: FakeInputFromController().makeInput()
        )
        _ = sut.transform(input: input)

        var observed: WelcomeUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        // Act
        startTrigger.send(())

        // Assert
        guard case .start = observed else {
            XCTFail("Expected navigator to emit .start, got \(String(describing: observed))")
            return
        }
    }
}
