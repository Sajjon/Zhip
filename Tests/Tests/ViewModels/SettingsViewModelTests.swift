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
import Foundation
import XCTest
import SingleLineControllerController
@testable import Zhip

/// Tests for `SettingsViewModel`.
///
/// Covers the lazy sections-on-viewWillAppear population, the pincode-vs-no-pincode
/// branch in the first section, the footer text, close-settings navigation, and
/// item-selection navigation to the step stored on the tapped cell.
final class SettingsViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var selectedIndexPath: PassthroughSubject<IndexPath, Never>!
    private var fakeController: FakeInputFromController!
    private var mockUseCase: MockPincodeUseCase!

    override func setUp() {
        super.setUp()
        selectedIndexPath = PassthroughSubject<IndexPath, Never>()
        fakeController = FakeInputFromController()
        mockUseCase = MockPincodeUseCase(pincode: nil)
    }

    override func tearDown() {
        cancellables.removeAll()
        mockUseCase = nil
        fakeController = nil
        selectedIndexPath = nil
        super.tearDown()
    }

    // MARK: - Sections

    func test_sections_buildsOnViewWillAppear() {
        let sut = makeSUT()
        let output = sut.transform(input: makeInput())
        var latest: [SectionModel<Void, SettingsItem>] = []
        output.sections.sink { latest = $0 }.store(in: &cancellables)

        fakeController.viewWillAppearSubject.send(())

        XCTAssertEqual(latest.count, 4)
        XCTAssertEqual(latest.map(\.items.count), [1, 3, 3, 2])
    }

    func test_sections_withoutConfiguredPincode_firstItemIsSetPincode() {
        mockUseCase = MockPincodeUseCase(pincode: nil)
        let sut = makeSUT()
        let output = sut.transform(input: makeInput())
        var latest: [SectionModel<Void, SettingsItem>] = []
        output.sections.sink { latest = $0 }.store(in: &cancellables)

        fakeController.viewWillAppearSubject.send(())

        XCTAssertEqual(latest.first?.items.first?.destination, .setPincode)
    }

    func test_sections_withConfiguredPincode_firstItemIsRemovePincode() throws {
        let pincode = try Pincode(digits: [.one, .two, .three, .four])
        mockUseCase = MockPincodeUseCase(pincode: pincode)
        let sut = makeSUT()
        let output = sut.transform(input: makeInput())
        var latest: [SectionModel<Void, SettingsItem>] = []
        output.sections.sink { latest = $0 }.store(in: &cancellables)

        fakeController.viewWillAppearSubject.send(())

        XCTAssertEqual(latest.first?.items.first?.destination, .removePincode)
    }

    // MARK: - Footer

    func test_footerText_isNonEmpty() {
        let sut = makeSUT()
        let output = sut.transform(input: makeInput())
        var footer: String?
        output.footerText.sink { footer = $0 }.store(in: &cancellables)

        XCTAssertFalse((footer ?? "").isEmpty)
    }

    // MARK: - Navigation

    func test_rightBarButton_emitsCloseSettings() {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var observed: SettingsNavigation?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        fakeController.rightBarButtonTriggerSubject.send(())

        XCTAssertEqual(observed, .closeSettings)
    }

    func test_selectedIndexPath_emitsItemDestination() {
        let sut = makeSUT()
        _ = sut.transform(input: makeInput())
        var observed: SettingsNavigation?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        fakeController.viewWillAppearSubject.send(())
        selectedIndexPath.send(IndexPath(row: 1, section: 3))

        XCTAssertEqual(observed, .removeWallet)
    }

    private func makeSUT() -> SettingsViewModel {
        SettingsViewModel(useCase: mockUseCase)
    }

    private func makeInput() -> SettingsViewModel.Input {
        SettingsViewModel.Input(
            fromView: .init(selectedIndexPath: selectedIndexPath.eraseToAnyPublisher()),
            fromController: fakeController.makeInput()
        )
    }
}
