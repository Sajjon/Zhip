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

import UIKit

/// Compound "label + selectable value" component used to display read-only
/// fields like wallet addresses and transaction hashes — the title sits
/// above a `UITextView` (chosen over `UILabel` so users can long-press
/// to copy the value).
///
/// Construction is two-phase: first `init` (no styling), then `withStyles(...)`.
/// Forgetting the second call trips the `incorrectImplementation` guard in
/// `layoutSubviews()` so the omission surfaces immediately.
final class TitledValueView: UIStackView {
    /// Tracks whether `withStyles(_:)` has been called. Read in `layoutSubviews`
    /// to enforce the two-phase construction contract.
    private var isSetup = false
    /// Header label; `fileprivate` so the binder extension below can read it.
    fileprivate let titleLabel = UILabel()
    /// Read-only text view holding the value (selectable for copy).
    fileprivate let valueTextView = UITextView()

    /// Crashes loudly if styling was never applied — see the type-level note.
    override func layoutSubviews() {
        super.layoutSubviews()
        guard isSetup else { incorrectImplementation("you should call `withStyles` method after init") }
    }
}

extension TitledValueView {
    /// Applies title/value/stack styles and seats the subviews. Must be called
    /// once after init (see `layoutSubviews` guard).
    ///
    /// - Parameters:
    ///   - titleStyle: Override for the title label style. Defaults to `UIFont.callToAction`.
    ///   - valueStyle: Override for the value text view style. Defaults to a
    ///     non-editable, non-scrollable body-font configuration.
    ///   - stackViewStyle: Override for the outer stack layout. Defaults to
    ///     `spacing: 8`, no margins.
    ///   - customizeTitleStyle: Hook to mutate the resolved title style after
    ///     it's been chosen — lets call sites tweak just one attribute.
    func withStyles(
        forTitle titleStyle: UILabel.Style? = nil,
        forValue valueStyle: UITextView.Style? = nil,
        forStackView stackViewStyle: UIStackView.Style? = nil,
        customizeTitleStyle: ((UILabel.Style) -> (UILabel.Style))? = nil
    ) {
        defer { isSetup = true }
        var titleStyleUsed = titleStyle ?? UILabel.Style(font: .callToAction)
        titleStyleUsed = customizeTitleStyle?(titleStyleUsed) ?? titleStyleUsed

        // The negative left/right insets compensate for an Apple quirk where
        // UITextView text is offset 5pt inward relative to UILabel — without
        // these the title and value would visually misalign.
        let valueStyleUsed = valueStyle ?? UITextView.Style(
            font: UIFont.Label.body,
            isEditable: false,
            isScrollEnabled: false,
            // UILabel and UITextView horizontal alignment differs, change inset: stackoverflow.com/a/45113744/1311272
            contentInset: UIEdgeInsets(top: 0, left: -5, bottom: 0, right: -5)
        )

        titleLabel.withStyle(titleStyleUsed)
        valueTextView.withStyle(valueStyleUsed)
        translatesAutoresizingMaskIntoConstraints = false

        let defaultStackViewStyle = UIStackView.Style(
            spacing: 8,
            layoutMargins: .zero,
            isLayoutMarginsRelativeArrangement: false
        )

        let stackViewStyleUsed = stackViewStyle ?? defaultStackViewStyle

        apply(style: stackViewStyleUsed)
        // Insert in reverse order at index 0 so the final stack reads
        // `[titleLabel, valueTextView]` top→bottom.
        [valueTextView, titleLabel].forEach { insertArrangedSubview($0, at: 0) }
    }

    /// Updates the value text view's contents from any `CustomStringConvertible`.
    func setValue(_ value: CustomStringConvertible) {
        valueTextView.text = value.description
    }

    /// Sets the title and returns `self` for chaining (`.titled("Address")`).
    @discardableResult
    func titled(_ text: CustomStringConvertible) -> TitledValueView {
        titleLabel.text = text.description
        return self
    }
}

extension TitledValueView {
    /// Reactive binder for the title text — re-exports `titleLabel.textBinder`.
    var titleBinder: Binder<String?> {
        titleLabel.textBinder
    }

    /// Reactive binder for the value text — re-exports `valueTextView.textBinder`.
    var valueBinder: Binder<String> {
        valueTextView.textBinder
    }
}
