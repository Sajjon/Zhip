import UIKit
import XCTest
@testable import AppFeature

@MainActor
final class UILabelStylingTests: XCTestCase {
    // MARK: - apply

    func test_apply_appliesAllProvidedAttributes() {
        let label = UILabel()
        let style = UILabel.Style(
            text: "hello",
            textAlignment: .center,
            textColor: .red,
            font: .systemFont(ofSize: 12),
            numberOfLines: 3,
            backgroundColor: .yellow,
            adjustsFontSizeMinimumScaleFactor: 0.5
        )

        label.apply(style: style)

        XCTAssertEqual(label.text, "hello")
        XCTAssertEqual(label.textAlignment, .center)
        XCTAssertEqual(label.textColor, .red)
        XCTAssertEqual(label.font, .systemFont(ofSize: 12))
        XCTAssertEqual(label.numberOfLines, 3)
        XCTAssertEqual(label.backgroundColor, .yellow)
        XCTAssertTrue(label.adjustsFontSizeToFitWidth)
        XCTAssertEqual(label.minimumScaleFactor, 0.5)
    }

    func test_apply_appliesDefaultsWhenStyleIsEmpty() {
        let label = UILabel()
        label.apply(style: UILabel.Style())

        XCTAssertEqual(label.numberOfLines, 1)
        XCTAssertEqual(label.textAlignment, .left)
        XCTAssertEqual(label.backgroundColor, .clear)
    }

    // MARK: - withStyle

    func test_withStyle_returnsSelfAndAppliesStyle() {
        let label = UILabel()
        let result = label.withStyle(.body)
        XCTAssertTrue(result === label)
        XCTAssertFalse(label.translatesAutoresizingMaskIntoConstraints)
    }

    func test_withStyle_customize_isApplied() {
        let label = UILabel()
        label.withStyle(.body) { $0.text("custom").textColor(.green) }
        XCTAssertEqual(label.text, "custom")
        XCTAssertEqual(label.textColor, .green)
    }

    // MARK: - Style customizers

    func test_style_text_customizer() {
        let style = UILabel.Style().text("foo")
        XCTAssertEqual(style.text, "foo")
    }

    func test_style_font_customizer() {
        let style = UILabel.Style().font(.systemFont(ofSize: 7))
        XCTAssertEqual(style.font, .systemFont(ofSize: 7))
    }

    func test_style_numberOfLines_customizer() {
        let style = UILabel.Style().numberOfLines(5)
        XCTAssertEqual(style.numberOfLines, 5)
    }

    func test_style_textAlignment_customizer() {
        let style = UILabel.Style().textAlignment(.right)
        XCTAssertEqual(style.textAlignment, .right)
    }

    func test_style_textColor_customizer() {
        let style = UILabel.Style().textColor(.blue)
        XCTAssertEqual(style.textColor, .blue)
    }

    func test_style_minimumScaleFactor_customizer() {
        let style = UILabel.Style().minimumScaleFactor(0.25)
        XCTAssertEqual(style.adjustsFontSizeMinimumScaleFactor, 0.25)
    }

    // MARK: - Presets

    func test_preset_impression_hasFont() {
        XCTAssertNotNil(UILabel.Style.impression.font)
    }

    func test_preset_header_hasZeroNumberOfLines() {
        XCTAssertEqual(UILabel.Style.header.numberOfLines, 0)
    }

    func test_preset_title_hasFont() {
        XCTAssertNotNil(UILabel.Style.title.font)
    }

    func test_preset_body_hasZeroNumberOfLines() {
        XCTAssertEqual(UILabel.Style.body.numberOfLines, 0)
    }

    func test_preset_checkbox_hasZeroNumberOfLines() {
        XCTAssertEqual(UILabel.Style.checkbox.numberOfLines, 0)
    }

    // MARK: - Mergeable

    func test_merged_yieldToOther_otherWins() {
        let lhs = UILabel.Style(textAlignment: .left, font: .systemFont(ofSize: 10))
        let rhs = UILabel.Style(textAlignment: .right, font: .systemFont(ofSize: 14))

        let merged = lhs.merged(other: rhs, mode: .yieldToOther)

        XCTAssertEqual(merged.textAlignment, .right)
        XCTAssertEqual(merged.font, .systemFont(ofSize: 14))
    }

    func test_merged_overrideOther_selfWins() {
        let lhs = UILabel.Style(textAlignment: .left, font: .systemFont(ofSize: 10))
        let rhs = UILabel.Style(textAlignment: .right, font: .systemFont(ofSize: 14))

        let merged = lhs.merged(other: rhs, mode: .overrideOther)

        XCTAssertEqual(merged.textAlignment, .left)
        XCTAssertEqual(merged.font, .systemFont(ofSize: 10))
    }
}
