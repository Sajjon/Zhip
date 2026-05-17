@testable import AppFeature
import Combine
import NanoViewControllerController
import NanoViewControllerCore
import XCTest

@MainActor
final class ChooseWalletViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var createNewTrigger: PassthroughSubject<Void, Never>!
    private var restoreTrigger: PassthroughSubject<Void, Never>!
    private var fakeController: FakeInputFromController!

    override func setUp() {
        super.setUp()
        createNewTrigger = PassthroughSubject<Void, Never>()
        restoreTrigger = PassthroughSubject<Void, Never>()
        fakeController = FakeInputFromController()
    }

    override func tearDown() {
        cancellables.removeAll()
        createNewTrigger = nil
        restoreTrigger = nil
        fakeController = nil
        super.tearDown()
    }

    func test_createNewWalletTrigger_emitsCreateNewWallet() {
        let (_, output) = makeSUT()
        var observed: ChooseWalletUserAction?
        output.navigation.sink { observed = $0 }.store(in: &cancellables)

        createNewTrigger.send(())

        guard case .createNewWallet = observed else {
            return XCTFail("Expected .createNewWallet, got \(String(describing: observed))")
        }
    }

    func test_restoreWalletTrigger_emitsRestoreWallet() {
        let (_, output) = makeSUT()
        var observed: ChooseWalletUserAction?
        output.navigation.sink { observed = $0 }.store(in: &cancellables)

        restoreTrigger.send(())

        guard case .restoreWallet = observed else {
            return XCTFail("Expected .restoreWallet, got \(String(describing: observed))")
        }
    }

    private func makeSUT() -> (ChooseWalletViewModel, Output<ChooseWalletViewModel.Publishers, ChooseWalletUserAction>) {
        let sut = ChooseWalletViewModel()
        let input = ChooseWalletViewModel.Input(
            fromView: .init(
                createNewWalletTrigger: createNewTrigger.eraseToAnyPublisher(),
                restoreWalletTrigger: restoreTrigger.eraseToAnyPublisher()
            ),
            fromController: fakeController.makeInput()
        )
        let output = sut.transform(input: input)
        return (sut, output)
    }
}
