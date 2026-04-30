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
import SingleLineControllerController
import UIKit
import XCTest

/// Drives the `SetPincodeCoordinator` flow: ChoosePincode → ConfirmNewPincode
/// on selection, or straight to `.setPincode` on skip from either stage.
final class SetPincodeCoordinatorTests: XCTestCase {
    private var window: UIWindow!
    private var navigationController: NavigationBarLayoutingNavigationController!
    private var mockPincode: MockPincodeUseCase!
    private var cancellables: Set<AnyCancellable> = []
    private var sut: SetPincodeCoordinator!

    override func setUp() {
        super.setUp()
        mockPincode = MockPincodeUseCase()
        Container.shared.pincodeUseCase.register { [unowned self] in mockPincode }
        navigationController = NavigationBarLayoutingNavigationController()
        window = UIWindow(frame: .init(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        sut = SetPincodeCoordinator(
            navigationController: navigationController,
            useCase: mockPincode
        )
    }

    override func tearDown() {
        drainRunLoop()
        cancellables.removeAll()
        sut = nil
        window.isHidden = true
        window = nil
        navigationController = nil
        Container.shared.manager.reset()
        mockPincode = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func top<T>(as _: T.Type) -> T? {
        navigationController.viewControllers.last as? T
    }

    private func makePincode() throws -> Pincode {
        try Pincode(digits: [.zero, .one, .two, .three])
    }

    // MARK: - start

    func test_start_pushesChoosePincodeAsRoot() {
        sut.start()

        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers.first is ChoosePincode)
    }

    // MARK: - ChoosePincode branches

    func test_chosePincode_pushesConfirmNewPincode() throws {
        sut.start()
        let choose = try XCTUnwrap(top(as: ChoosePincode.self))

        try choose.viewModel.navigator.next(.chosePincode(makePincode()))
        drainRunLoop()

        XCTAssertTrue(top(as: ConfirmNewPincode.self) != nil)
    }

    func test_chooseSkip_bubblesSetPincode() throws {
        sut.start()
        var received: SetPincodeCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)
        let choose = try XCTUnwrap(top(as: ChoosePincode.self))

        choose.viewModel.navigator.next(.skip)
        drainRunLoop()

        XCTAssertTrue(mockPincode.skipSettingUpPincodeCallCount > 0)
        if case .setPincode = received { } else {
            XCTFail("expected .setPincode, got \(String(describing: received))")
        }
    }

    // MARK: - ConfirmNewPincode branches

    func test_confirmPincodeConfirm_bubblesSetPincode() throws {
        sut.start()
        try top(as: ChoosePincode.self)?.viewModel.navigator.next(.chosePincode(makePincode()))
        drainRunLoop()
        var received: SetPincodeCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)
        let confirm = try XCTUnwrap(top(as: ConfirmNewPincode.self))

        confirm.viewModel.navigator.next(.confirmPincode)
        drainRunLoop()

        if case .setPincode = received { } else {
            XCTFail("expected .setPincode, got \(String(describing: received))")
        }
    }

    func test_confirmPincodeSkip_bubblesSetPincodeAndCallsSkip() throws {
        sut.start()
        try top(as: ChoosePincode.self)?.viewModel.navigator.next(.chosePincode(makePincode()))
        drainRunLoop()
        var received: SetPincodeCoordinatorNavigationStep?
        sut.navigator.navigation.sink { received = $0 }.store(in: &cancellables)
        let confirm = try XCTUnwrap(top(as: ConfirmNewPincode.self))

        confirm.viewModel.navigator.next(.skip)
        drainRunLoop()

        XCTAssertTrue(mockPincode.skipSettingUpPincodeCallCount > 0)
        if case .setPincode = received { } else {
            XCTFail("expected .setPincode, got \(String(describing: received))")
        }
    }
}
