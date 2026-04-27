import UIKit
import XCTest
@testable import Zhip

final class UITextViewStylingTests: XCTestCase {
    // MARK: - apply

    func test_apply_appliesAllProvidedAttributes() {
        let textView = UITextView()
        let style = UITextView.Style(
            text: "hello",
            textAlignment: .center,
            font: .systemFont(ofSize: 12),
            textColor: .red,
            backgroundColor: .yellow,
            isEditable: false,
            isSelectable: false,
            isScrollEnabled: false,
            contentInset: UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4)
        )

        textView.apply(style: style)

        XCTAssertEqual(textView.text, "hello")
        XCTAssertEqual(textView.textAlignment, .center)
        XCTAssertEqual(textView.font, .systemFont(ofSize: 12))
        XCTAssertEqual(textView.textColor, .red)
        XCTAssertEqual(textView.backgroundColor, .yellow)
        XCTAssertFalse(textView.isEditable)
        XCTAssertFalse(textView.isSelectable)
        XCTAssertFalse(textView.isScrollEnabled)
        XCTAssertEqual(textView.contentInset, UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4))
    }

    func test_apply_appliesDefaultsWhenStyleIsEmpty() {
        let textView = UITextView()
        textView.apply(style: UITextView.Style())

        XCTAssertEqual(textView.textAlignment, .left)
        XCTAssertTrue(textView.isEditable)
        XCTAssertTrue(textView.isSelectable)
        XCTAssertTrue(textView.isScrollEnabled)
        XCTAssertEqual(textView.contentInset, .zero)
    }

    // MARK: - withStyle

    func test_withStyle_returnsSelfAndApplies() {
        let textView = UITextView()
        let result = textView.withStyle(.editable)
        XCTAssertTrue(result === textView)
        XCTAssertTrue(textView.isEditable)
    }

    func test_withStyle_customizeIsApplied() {
        let textView = UITextView()
        textView.withStyle(.editable) { $0.text("custom").textColor(.green) }
        XCTAssertEqual(textView.text, "custom")
        XCTAssertEqual(textView.textColor, .green)
    }

    // MARK: - Style customizer chain

    func test_style_textCustomizer() {
        let style = UITextView.Style().text("foo")
        XCTAssertEqual(style.text, "foo")
    }

    func test_style_fontCustomizer() {
        let style = UITextView.Style().font(.systemFont(ofSize: 7))
        XCTAssertEqual(style.font, .systemFont(ofSize: 7))
    }

    func test_style_textAlignmentCustomizer() {
        let style = UITextView.Style().textAlignment(.right)
        XCTAssertEqual(style.textAlignment, .right)
    }

    func test_style_textColorCustomizer() {
        let style = UITextView.Style().textColor(.blue)
        XCTAssertEqual(style.textColor, .blue)
    }

    func test_style_isSelectableCustomizer() {
        let style = UITextView.Style().isSelectable(false)
        XCTAssertEqual(style.isSelectable, false)
    }

    func test_style_isScrollEnabledCustomizer() {
        let style = UITextView.Style().isScrollEnabled(true)
        XCTAssertEqual(style.isScrollEnabled, true)
    }

    // MARK: - Presets

    func test_preset_nonEditable() {
        XCTAssertEqual(UITextView.Style.nonEditable.isEditable, false)
    }

    func test_preset_nonSelectable() {
        let style = UITextView.Style.nonSelectable
        XCTAssertEqual(style.textAlignment, .center)
        XCTAssertEqual(style.isEditable, false)
        XCTAssertEqual(style.isSelectable, false)
    }

    func test_preset_editable() {
        XCTAssertEqual(UITextView.Style.editable.isEditable, true)
    }

    func test_preset_header() {
        let style = UITextView.Style.header
        XCTAssertEqual(style.textAlignment, .center)
        XCTAssertEqual(style.isEditable, false)
    }

    // MARK: - Mergeable

    func test_merged_yieldToOther_otherWins() {
        let lhs = UITextView.Style(textAlignment: .left, font: .systemFont(ofSize: 10))
        let rhs = UITextView.Style(textAlignment: .right, font: .systemFont(ofSize: 14))

        let merged = lhs.merged(other: rhs, mode: .yieldToOther)

        XCTAssertEqual(merged.textAlignment, .right)
        XCTAssertEqual(merged.font, .systemFont(ofSize: 14))
    }

    func test_merged_overrideOther_selfWins() {
        let lhs = UITextView.Style(textAlignment: .left, font: .systemFont(ofSize: 10))
        let rhs = UITextView.Style(textAlignment: .right, font: .systemFont(ofSize: 14))

        let merged = lhs.merged(other: rhs, mode: .overrideOther)

        XCTAssertEqual(merged.textAlignment, .left)
        XCTAssertEqual(merged.font, .systemFont(ofSize: 10))
    }
}
