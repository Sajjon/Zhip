import Combine
import XCTest
import SingleLineControllerController
@testable import Zhip

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
        let sut = makeSUT()
        var observed: EnsureThatYouAreNotBeingWatchedUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        understandTrigger.send(())

        guard case .understand = observed else {
            return XCTFail("Expected .understand, got \(String(describing: observed))")
        }
    }

    func test_leftBarButtonTrigger_emitsCancel() {
        let sut = makeSUT()
        var observed: EnsureThatYouAreNotBeingWatchedUserAction?
        sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

        fakeController.leftBarButtonTriggerSubject.send(())

        guard case .cancel = observed else {
            return XCTFail("Expected .cancel, got \(String(describing: observed))")
        }
    }

    private func makeSUT() -> EnsureThatYouAreNotBeingWatchedViewModel {
        let sut = EnsureThatYouAreNotBeingWatchedViewModel()
        let input = EnsureThatYouAreNotBeingWatchedViewModel.Input(
            fromView: .init(
                understandTrigger: understandTrigger.eraseToAnyPublisher()
            ),
            fromController: fakeController.makeInput()
        )
        _ = sut.transform(input: input)
        return sut
    }
}
