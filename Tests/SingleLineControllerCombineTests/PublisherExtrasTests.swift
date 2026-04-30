// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
@testable import SingleLineControllerCombine
import XCTest

/// Tests for `Publisher+Extras` operators (`replaceErrorWithEmpty`,
/// `mapToVoid`, `filterNil`, `orEmpty`, `flatMapLatest`, `withLatestFrom`,
/// `ifEmpty(switchTo:)`).
final class PublisherExtrasTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - replaceErrorWithEmpty

    func test_replaceErrorWithEmpty_swallowsError_completesWithoutValue() {
        struct TestError: Error {}
        var received: [Int] = []
        var completed = false

        Fail<Int, TestError>(error: TestError())
            .replaceErrorWithEmpty()
            .sink(
                receiveCompletion: { _ in completed = true },
                receiveValue: { received.append($0) }
            )
            .store(in: &cancellables)

        XCTAssertTrue(received.isEmpty)
        XCTAssertTrue(completed)
    }

    // MARK: - mapToVoid

    func test_mapToVoid_emitsVoidForEachUpstreamValue() {
        var count = 0

        [1, 2, 3].publisher
            .mapToVoid()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in count += 1 })
            .store(in: &cancellables)

        XCTAssertEqual(count, 3)
    }

    // MARK: - filterNil

    func test_filterNil_dropsNilsAndUnwraps() {
        var received: [Int] = []

        ([1, nil, 2, nil, 3] as [Int?]).publisher
            .filterNil()
            .sink { received.append($0) }
            .store(in: &cancellables)

        XCTAssertEqual(received, [1, 2, 3])
    }

    // MARK: - orEmpty

    func test_orEmpty_publisher_replacesNilWithEmptyString() {
        var received: [String] = []

        (["hi", nil, "bye"] as [String?]).publisher
            .orEmpty
            .sink { received.append($0) }
            .store(in: &cancellables)

        XCTAssertEqual(received, ["hi", "", "bye"])
    }

    func test_orEmpty_anyPublisher_replacesNilWithEmptyString() {
        var received: [String] = []

        let publisher: AnyPublisher<String?, Never> = (["hi", nil] as [String?]).publisher.eraseToAnyPublisher()
        publisher
            .orEmpty
            .sink { received.append($0) }
            .store(in: &cancellables)

        XCTAssertEqual(received, ["hi", ""])
    }

    // MARK: - flatMapLatest

    func test_flatMapLatest_neverFailure_switchesToLatestInner() {
        var received: [Int] = []
        let outer = PassthroughSubject<Int, Never>()

        outer
            .flatMapLatest { Just($0 * 10) }
            .sink { received.append($0) }
            .store(in: &cancellables)

        outer.send(1)
        outer.send(2)

        XCTAssertEqual(received, [10, 20])
    }

    func test_flatMapLatest_genericFailure_switchesToLatestInner() {
        struct TestError: Error {}
        var received: [Int] = []

        let outer = PassthroughSubject<Int, TestError>()

        outer
            .flatMapLatest { Just($0).setFailureType(to: TestError.self) }
            .sink(receiveCompletion: { _ in }, receiveValue: { received.append($0) })
            .store(in: &cancellables)

        outer.send(7)
        outer.send(8)

        XCTAssertEqual(received, [7, 8])
    }

    // MARK: - withLatestFrom

    func test_withLatestFrom_emitsLatestOtherWhenUpstreamFires() {
        let upstream = PassthroughSubject<Void, Never>()
        let other = CurrentValueSubject<Int, Never>(0)
        var received: [Int] = []

        upstream
            .withLatestFrom(other)
            .sink { received.append($0) }
            .store(in: &cancellables)

        other.send(42)
        upstream.send(())
        other.send(99)
        upstream.send(())

        XCTAssertEqual(received, [42, 99])
    }

    func test_withLatestFrom_resultSelector_combinesValues() {
        let upstream = PassthroughSubject<Int, Never>()
        let other = CurrentValueSubject<Int, Never>(10)
        var received: [Int] = []

        upstream
            .withLatestFrom(other) { up, oth in up + oth }
            .sink { received.append($0) }
            .store(in: &cancellables)

        upstream.send(5)
        other.send(20)
        upstream.send(7)

        XCTAssertEqual(received, [15, 27])
    }

    func test_withLatestFrom_dropsValueWhenOtherHasNotEmitted() {
        let upstream = PassthroughSubject<Void, Never>()
        let other = PassthroughSubject<Int, Never>()
        var received: [Int] = []

        upstream
            .withLatestFrom(other)
            .sink { received.append($0) }
            .store(in: &cancellables)

        upstream.send(())
        XCTAssertTrue(received.isEmpty)

        other.send(1)
        upstream.send(())
        XCTAssertEqual(received, [1])
    }

    // MARK: - ifEmpty(switchTo:)

    func test_ifEmpty_emitsReplacementWhenUpstreamIsEmpty() {
        var received: [Int] = []

        Empty<Int, Never>()
            .ifEmpty(switchTo: Just(99).eraseToAnyPublisher())
            .sink { received.append($0) }
            .store(in: &cancellables)

        XCTAssertEqual(received, [99])
    }

    func test_ifEmpty_doesNotEmitReplacementWhenUpstreamHasValues() {
        var received: [Int] = []

        Just(7)
            .ifEmpty(switchTo: Just(99).eraseToAnyPublisher())
            .sink { received.append($0) }
            .store(in: &cancellables)

        XCTAssertEqual(received, [7])
    }
}
