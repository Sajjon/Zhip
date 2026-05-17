@testable import AppFeature
import Combine
import NanoViewControllerController
import NanoViewControllerCore
import XCTest

@MainActor
final class EnsureThatYouAreNotBeingWatchedViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []
    private var understandTrigger: PassthroughSubject<Void, Never>!
    private var fakeController: FakeInputFromController!

    override func setUp() {
        super.setUp()
        understandTrigger = PassthroughSubject<Void, Never>()
        fakeController = FakeInputFromController()
    }

    override func tearDown() {
        cancellables.removeAll()
        understandTrigger = nil
        fakeController = nil
        super.tearDown()
    }

    func test_understandTrigger_emitsUnderstand() {
        let (_, output) = makeSUT()
        var observed: EnsureThatYouAreNotBeingWatchedUserAction?
        output.navigation.sink { observed = $0 }.store(in: &cancellables)

        understandTrigger.send(())

        guard case .understand = observed else {
            return XCTFail("Expected .understand, got \(String(describing: observed))")
        }
    }

    func test_leftBarButtonTrigger_emitsCancel() {
        let (_, output) = makeSUT()
        var observed: EnsureThatYouAreNotBeingWatchedUserAction?
        output.navigation.sink { observed = $0 }.store(in: &cancellables)

        fakeController.leftBarButtonTriggerSubject.send(())

        guard case .cancel = observed else {
            return XCTFail("Expected .cancel, got \(String(describing: observed))")
        }
    }

    private func makeSUT() -> (EnsureThatYouAreNotBeingWatchedViewModel, Output<EnsureThatYouAreNotBeingWatchedViewModel.Publishers, EnsureThatYouAreNotBeingWatchedViewModel.NavigationStep>) {
        let sut = EnsureThatYouAreNotBeingWatchedViewModel()
        let input = EnsureThatYouAreNotBeingWatchedViewModel.Input(
            fromView: .init(
                understandTrigger: understandTrigger.eraseToAnyPublisher()
            ),
            fromController: fakeController.makeInput()
        )
        let output = sut.transform(input: input)
        return (sut, output)
    }
}
