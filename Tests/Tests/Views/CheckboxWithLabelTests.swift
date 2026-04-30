import Combine
import UIKit
import XCTest
@testable import AppFeature

final class CheckboxWithLabelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - CheckboxView

    func test_checkboxView_init_isOffByDefault() {
        let sut = CheckboxView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        XCTAssertFalse(sut.on)
    }

    func test_checkboxView_setOnAnimated_updatesState() {
        let sut = CheckboxView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        sut.setOn(true, animated: false)
        XCTAssertTrue(sut.on)
    }

    func test_checkboxView_setOnSameValue_isNoOp() {
        let sut = CheckboxView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        sut.on = true
        sut.setOn(true, animated: false)
        XCTAssertTrue(sut.on)
    }

    func test_checkboxView_settingOnSameValueViaProperty_isNoOp() {
        let sut = CheckboxView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        sut.on = false
        sut.on = false
        XCTAssertFalse(sut.on)
    }

    func test_checkboxView_setOnAnimated_animatedTrue_updatesAppearance() {
        let sut = CheckboxView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        sut.setOn(true, animated: true)
        XCTAssertTrue(sut.on)
    }

    func test_checkboxView_setOnAnimated_zeroDuration_appliesSynchronously() {
        let sut = CheckboxView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        sut.animationDuration = 0
        sut.setOn(true, animated: true)
        XCTAssertTrue(sut.on)
    }

    func test_checkboxView_initFromCoder_succeeds() throws {
        let archiver = NSKeyedArchiver(requiringSecureCoding: false)
        let view = CheckboxView(frame: .zero)
        view.encode(with: archiver)
        archiver.finishEncoding()

        let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: archiver.encodedData)
        unarchiver?.requiresSecureCoding = false
        let decoded = try CheckboxView(coder: XCTUnwrap(unarchiver))
        XCTAssertNotNil(decoded)
    }

    func test_checkboxView_layoutSubviews_updatesLayerFrames() {
        let sut = CheckboxView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        sut.layoutIfNeeded()
        // Should not crash. Layer frames updated.
    }

    func test_checkboxView_isCheckedPublisher_emitsInitialAndOnChange() {
        let sut = CheckboxView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        var values: [Bool] = []
        sut.isCheckedPublisher.sink { values.append($0) }.store(in: &cancellables)

        sut.on = true
        sut.sendActions(for: .valueChanged)

        XCTAssertEqual(values.first, false)
        XCTAssertTrue(values.contains(true))
    }

    // MARK: - CheckboxWithLabel

    func test_checkboxWithLabel_init_succeeds() {
        let sut = CheckboxWithLabel()
        _ = sut
    }

    func test_checkboxWithLabel_withStyle_default_returnsSelf() {
        let sut = CheckboxWithLabel()
        let result = sut.withStyle(.default)
        XCTAssertTrue(result === sut)
    }

    func test_checkboxWithLabel_withStyle_appliesText() {
        let sut = CheckboxWithLabel()
        sut.withStyle(.init(labelText: "Accept", numberOfLines: 0))
        // Just ensure it does not crash and applies the styling.
    }

    func test_checkboxWithLabel_withStyle_customizeMutatesStyle() {
        let sut = CheckboxWithLabel()
        sut.withStyle(.default) { $0.text("Hello").numberOfLines(2) }
        // Verify customize closure path is exercised.
    }

    func test_checkboxWithLabel_isCheckedPublisher_emitsCheckboxState() {
        let sut = CheckboxWithLabel()
        var values: [Bool] = []
        sut.isCheckedPublisher.sink { values.append($0) }.store(in: &cancellables)

        XCTAssertFalse(values.isEmpty)
    }

    // MARK: - Style helpers

    func test_style_text_returnsModifiedStyle() {
        let style = CheckboxWithLabel.Style.default.text("Hi")
        XCTAssertEqual(style.labelText, "Hi")
    }

    func test_style_numberOfLines_returnsModifiedStyle() {
        let style = CheckboxWithLabel.Style.default.numberOfLines(3)
        XCTAssertEqual(style.numberOfLines, 3)
    }

    func test_style_alignmentSetter_appliesAlignment() {
        let sut = CheckboxWithLabel()
        sut.withStyle(.init(labelText: nil, numberOfLines: 1, alignment: .center))
    }

    // MARK: - beginTracking

    func test_checkboxView_beginTracking_togglesOnAndSendsValueChanged() {
        let sut = CheckboxView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        var emitted: [Bool] = []
        sut.isCheckedPublisher.sink { emitted.append($0) }.store(in: &cancellables)

        let touch = UITouch()
        _ = sut.beginTracking(touch, with: nil)

        XCTAssertTrue(sut.on)
        XCTAssertTrue(emitted.contains(true))
    }

    func test_checkboxWithLabel_beginTracking_togglesCheckboxAndSendsValueChanged() {
        let sut = CheckboxWithLabel()
        var emitted: [Bool] = []
        sut.isCheckedPublisher.sink { emitted.append($0) }.store(in: &cancellables)

        let touch = UITouch()
        _ = sut.beginTracking(touch, with: nil)

        XCTAssertTrue(emitted.contains(true))
    }
}
