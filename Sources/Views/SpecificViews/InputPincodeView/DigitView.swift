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
import SingleLineControllerCore

/// Single-character display cell used inside `InputPincodeView` — one big
/// glyph (digit or bullet) with a coloured underline below it.
///
/// In secure mode the underlying digit is replaced with a "•" so the user's
/// pincode isn't shoulder-surfable; the underline colour reflects validation
/// state via `colorUnderlineView(with:)`.
final class DigitView: UIView {
    /// The visible glyph — either the typed digit or a "•" depending on
    /// `isSecureTextEntry`.
    private lazy var label = UILabel()

    /// Coloured underline beneath the digit. 3pt tall — driven by validation
    /// state rather than typed content.
    private lazy var underline: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.height(3)
        view.backgroundColor = AnyValidation.Color.validWithoutRemark
        return view
    }()

    /// Vertical stack composing the label above the underline.
    /// `internal` so the parent `InputPincodeView` can reach it for layout.
    lazy var stackView = UIStackView(arrangedSubviews: [label, underline])

    /// Whether to mask the digit as a bullet. Captured at init because
    /// changing it would require a full re-render and isn't needed.
    private let isSecureTextEntry: Bool

    /// Designated initialiser.
    /// - Parameter isSecureTextEntry: `true` masks input as "•"; `false` shows the digit.
    init(isSecureTextEntry: Bool) {
        self.isSecureTextEntry = isSecureTextEntry
        super.init(frame: .zero)
        setupSubviews()
    }

    /// Storyboard init — unsupported, traps to enforce programmatic-only use.
    required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }

    /// Sets the displayed glyph. In secure mode this *always* renders "•" when
    /// a digit is present; only `nil` clears the cell. So the caller can pass
    /// the real digit and trust this method to hide it.
    func updateWithNumberOrBullet(text: String?) {
        guard let text else {
            label.text = nil
            return
        }
        let labelText = isSecureTextEntry ? "•" : text
        label.text = labelText
    }

    /// Re-tints the underline. Used to communicate validation state
    /// (`AnyValidation.Color.error` for mismatch, etc.) without ever revealing
    /// the underlying digit.
    func colorUnderlineView(with color: UIColor) {
        underline.backgroundColor = color
    }

    /// Lays out label + underline in a tight vertical stack and picks a
    /// font: `.bigBang` for bullets (so the dot is large and readable) vs.
    /// `.impression` for plain digits.
    private func setupSubviews() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        stackView.edgesToSuperview()

        stackView.withStyle(.init(spacing: 4, layoutMargins: .zero))

        let font: UIFont = isSecureTextEntry ? .bigBang : .impression
        label.withStyle(.impression) {
            $0.textAlignment(.center)
                .font(font)
        }
    }
}

