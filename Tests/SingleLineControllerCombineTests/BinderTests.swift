// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import UIKit
import XCTest
@testable import SingleLineControllerCombine

/// Tests `Binder<Value>` — the write-only, main-thread UI primitive used by
/// `populate(with:)` to propagate ViewModel output into UIKit controls.
final class BinderTests: XCTestCase {
    final class Box {
        var value: Int = 0
    }

    func test_onMainThread_appliesValueSynchronously() {
        let box = Box()
        let binder = Binder(box) { $0.value = $1 }

        binder.on(42)

        XCTAssertEqual(box.value, 42)
    }

    func test_onBackgroundThread_appliesOnMainThreadAsynchronously() {
        let box = Box()
        let binder = Binder(box) { $0.value = $1 }
        let expectation = expectation(description: "applied")
        expectation.assertForOverFulfill = false

        DispatchQueue.global().async {
            binder.on(7)
            DispatchQueue.main.async {
                if box.value == 7 { expectation.fulfill() }
            }
        }

        wait(for: [expectation], timeout: 1)
    }

    func test_afterObjectDeallocated_writesAreDropped() throws {
        var box: Box? = Box()
        let binder = try Binder(XCTUnwrap(box)) { $0.value = $1 }

        box = nil
        binder.on(99)
        // No reference remains; just exercising the weak-guard path.
    }

    func test_uiViewIsVisibleBinder_togglesIsHidden() {
        let view = UIView()
        let binder = view.isVisibleBinder

        binder.on(true)
        XCTAssertFalse(view.isHidden)

        binder.on(false)
        XCTAssertTrue(view.isHidden)
    }

    func test_uiImageViewImageBinder_setsImage() {
        let imageView = UIImageView()
        let image = UIImage(systemName: "star")

        imageView.imageBinder.on(image)

        XCTAssertNotNil(imageView.image)
    }

    func test_bindingOperator_writesIntoBinder() {
        let box = Box()
        let binder = Binder(box) { $0.value = $1 }
        let subject = PassthroughSubject<Int, Never>()
        var cancellables: Set<AnyCancellable> = []
        let expectation = expectation(description: "applied")

        (subject.eraseToAnyPublisher() --> binder).store(in: &cancellables)
        subject.send(11)
        DispatchQueue.main.async {
            if box.value == 11 { expectation.fulfill() }
        }

        wait(for: [expectation], timeout: 1)
    }

    func test_bindingOperator_writesIntoLabel() {
        let label = UILabel()
        let subject = PassthroughSubject<String, Never>()
        var cancellables: Set<AnyCancellable> = []
        let expectation = expectation(description: "applied")

        (subject.eraseToAnyPublisher() --> label).store(in: &cancellables)
        subject.send("hello")
        DispatchQueue.main.async {
            if label.text == "hello" { expectation.fulfill() }
        }

        wait(for: [expectation], timeout: 1)
    }

    func test_bindingOperator_writesIntoTextView() {
        let textView = UITextView()
        let subject = PassthroughSubject<String, Never>()
        var cancellables: Set<AnyCancellable> = []
        let expectation = expectation(description: "applied")

        (subject.eraseToAnyPublisher() --> textView).store(in: &cancellables)
        subject.send("body")
        DispatchQueue.main.async {
            if textView.text == "body" { expectation.fulfill() }
        }

        wait(for: [expectation], timeout: 1)
    }

    func test_bindingOperator_optionalString_writesIntoLabel() {
        let label = UILabel()
        let subject = PassthroughSubject<String?, Never>()
        var cancellables: Set<AnyCancellable> = []
        let expectation = expectation(description: "applied")

        (subject.eraseToAnyPublisher() --> label).store(in: &cancellables)
        subject.send("optional-hello")
        DispatchQueue.main.async {
            if label.text == "optional-hello" { expectation.fulfill() }
        }

        wait(for: [expectation], timeout: 1)
    }

    func test_bindingOperator_optionalString_writesIntoTextView() {
        let textView = UITextView()
        let subject = PassthroughSubject<String?, Never>()
        var cancellables: Set<AnyCancellable> = []
        let expectation = expectation(description: "applied")

        (subject.eraseToAnyPublisher() --> textView).store(in: &cancellables)
        subject.send("optional-body")
        DispatchQueue.main.async {
            if textView.text == "optional-body" { expectation.fulfill() }
        }

        wait(for: [expectation], timeout: 1)
    }

    /// Exercises the `publisher --> Binder<T?>` overload (non-optional value lifted
    /// into an optional sink).
    func test_bindingOperator_nonOptionalIntoOptionalBinder() {
        let label = UILabel()
        let optionalBinder: Binder<String?> = Binder(label) { $0.text = $1 }
        let subject = PassthroughSubject<String, Never>()
        var cancellables: Set<AnyCancellable> = []
        let expectation = expectation(description: "applied")

        (subject.eraseToAnyPublisher() --> optionalBinder).store(in: &cancellables)
        subject.send("lifted")
        DispatchQueue.main.async {
            if label.text == "lifted" { expectation.fulfill() }
        }

        wait(for: [expectation], timeout: 1)
    }

    /// Exercises the `publisher-of-optional --> Binder<T?>` overload.
    func test_bindingOperator_optionalIntoOptionalBinder() {
        let label = UILabel()
        let binder: Binder<String?> = Binder(label) { $0.text = $1 }
        let subject = PassthroughSubject<String?, Never>()
        var cancellables: Set<AnyCancellable> = []
        let expectation = expectation(description: "applied")

        (subject.eraseToAnyPublisher() --> binder).store(in: &cancellables)
        subject.send("opt-to-opt")
        DispatchQueue.main.async {
            if label.text == "opt-to-opt" { expectation.fulfill() }
        }

        wait(for: [expectation], timeout: 1)
    }

    /// Covers the *initial* emission of `UISegmentedControl.valuePublisher` —
    /// the merged `Just(selectedSegmentIndex)` half. The `.valueChanged` half
    /// is exercised by the host-app ZhipTests, since `sendActions(for:)` on a
    /// segmented control that isn't in a window doesn't reliably fire its
    /// target/action chain inside an SPM test target with no host app.
    func test_uiSegmentedControl_valuePublisher_emitsInitialIndex() {
        let segmented = UISegmentedControl(items: ["A", "B", "C"])
        segmented.selectedSegmentIndex = 1
        var emitted: [Int] = []
        var cancellables: Set<AnyCancellable> = []

        segmented.valuePublisher.sink { emitted.append($0) }.store(in: &cancellables)

        XCTAssertEqual(emitted.first, 1)
    }
}
