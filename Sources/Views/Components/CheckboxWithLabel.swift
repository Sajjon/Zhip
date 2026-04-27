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

import Combine
import SingleLineControllerCombine
import TinyConstraints
import UIKit

// MARK: - CheckboxView (native replacement for BEMCheckBox)

/// A lightweight native checkbox control that replaces the abandoned BEMCheckBox library.
///
/// The shape is intentionally identical to the BEMCheckBox API surface that the
/// project relied on (`on`, `setOn(_:animated:)`, the colour properties), so
/// the swap was a drop-in replacement when BEMCheckBox stopped being maintained.
/// Drawing is done with two `CAShapeLayer`s — one for the rounded box, one for
/// the check stroke — both updated in `updateAppearance(animated:)`.
final class CheckboxView: UIControl {
    // MARK: Public API (matches the BEMCheckBox API that was used in this project)

    /// Current checked state. Setting it triggers a non-animated repaint via
    /// `didSet`; for animated transitions use `setOn(_:animated:)`.
    var on: Bool = false {
        didSet {
            guard oldValue != on else { return }
            updateAppearance(animated: false)
        }
    }

    /// Stroke colour of the checkmark glyph when `on == true`.
    var onCheckColor: UIColor = .white
    /// Fill colour of the box when `on == true`.
    var onFillColor: UIColor = .systemBlue
    /// Stroke colour of the box outline when `on == true`. Off-state uses `tintColor`.
    var onTintColor: UIColor = .systemBlue
    /// Line width for both the box outline and check stroke.
    var lineWidth: CGFloat = 1.5
    /// Corner radius of the rounded-rect box.
    var cornerRadius: CGFloat = 3
    /// Crossfade duration when toggling. Set to 0 to disable animation entirely.
    var animationDuration: TimeInterval = 0.2

    /// Programmatic toggle. Equivalent to `on = newValue` but with optional
    /// crossfade animation (the property setter is always non-animated).
    func setOn(_ on: Bool, animated: Bool) {
        guard self.on != on else { return }
        self.on = on
        updateAppearance(animated: animated)
    }

    // MARK: Private

    /// Background/outline shape for the rounded square box.
    private let boxLayer = CAShapeLayer()
    /// Foreground shape for the checkmark glyph.
    private let checkLayer = CAShapeLayer()

    /// Programmatic-init path: hook up layers + apply initial appearance.
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
        updateAppearance(animated: false)
    }

    /// Storyboard/XIB path — same setup. Required for `UIControl` codable conformance
    /// even though we don't actually load this control from XIBs.
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
        updateAppearance(animated: false)
    }

    /// Recompute layer frames + paths on every layout pass so corner radius and
    /// checkmark scale correctly track size changes.
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayerFrames()
    }

    /// Toggles state on touch-down (no need to wait for touch-up — feels snappier),
    /// fires `.valueChanged` so reactive subscribers see the new value, and
    /// returns `true` to accept the touch sequence.
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.beginTracking(touch, with: event)
        setOn(!on, animated: true)
        sendActions(for: .valueChanged)
        return true
    }
}

// MARK: - Private drawing

private extension CheckboxView {
    /// One-time layer hookup. Both layers are added to `self.layer` and start
    /// with no path — `layoutSubviews()` will call `updateLayerFrames()` to
    /// fill them in once we know our bounds.
    func setupLayers() {
        boxLayer.fillColor = UIColor.clear.cgColor
        boxLayer.lineWidth = lineWidth
        layer.addSublayer(boxLayer)

        checkLayer.fillColor = UIColor.clear.cgColor
        checkLayer.lineWidth = lineWidth
        checkLayer.lineCap = .round
        checkLayer.lineJoin = .round
        layer.addSublayer(checkLayer)
    }

    /// Recomputes the box's rounded-rect path and the checkmark's stroke path
    /// based on current bounds. Insetting by half the line width keeps the
    /// stroke from clipping at the edges.
    func updateLayerFrames() {
        let rect = bounds
        boxLayer.frame = rect
        checkLayer.frame = rect

        let path = UIBezierPath(
            roundedRect: rect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2),
            cornerRadius: cornerRadius
        )
        boxLayer.path = path.cgPath
        checkLayer.path = checkmarkPath(in: rect).cgPath
    }

    /// Returns a 3-point checkmark glyph normalised to `rect`.
    /// The hard-coded ratios (0.2/0.5, 0.42/0.72, 0.8/0.28) place the check
    /// visually centred — derived empirically rather than from a typeface.
    func checkmarkPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.2, y: h * 0.5))
        path.addLine(to: CGPoint(x: w * 0.42, y: h * 0.72))
        path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.28))
        return path
    }

    /// Recolours the layers based on `on` state, optionally animated.
    /// Off-state uses transparent fills so the inherited `tintColor` shows
    /// through for the box outline and the check is fully hidden.
    func updateAppearance(animated: Bool) {
        let strokeColor = on ? onFillColor.cgColor : tintColor.cgColor
        let fillColor = on ? onFillColor.cgColor : UIColor.clear.cgColor
        let checkStroke = on ? onCheckColor.cgColor : UIColor.clear.cgColor

        let apply = {
            self.boxLayer.strokeColor = strokeColor
            self.boxLayer.fillColor = fillColor
            self.checkLayer.strokeColor = checkStroke
        }

        if animated, animationDuration > 0 {
            UIView.animate(withDuration: animationDuration) { apply() }
        } else {
            apply()
        }
    }
}

// MARK: - CheckboxWithLabel

/// Horizontal checkbox + label compound used in onboarding scenes
/// (e.g. "I have backed up my password"). The whole thing is itself a
/// `UIControl`, so taps anywhere on the row toggle the box.
final class CheckboxWithLabel: UIControl {
    /// Description of the label's content/wrapping/alignment.
    /// (The checkbox itself has no per-instance customisation here — it's
    /// always 24×24, teal, with the same animation duration.)
    struct Style {
        /// Text to display in the label, if any.
        var labelText: String?
        /// `numberOfLines` for the label (0 = unlimited).
        var numberOfLines: Int?
        /// Stack-view alignment between checkbox and label. Defaults to
        /// `.top` for multi-line labels, `.fill` for single-line.
        var alignment: UIStackView.Alignment?
        init(
            labelText: String? = nil,
            numberOfLines: Int? = nil,
            alignment: UIStackView.Alignment? = nil
        ) {
            self.labelText = labelText
            self.numberOfLines = numberOfLines
            self.alignment = alignment
        }
    }

    /// Side length of the checkbox glyph in points (24×24).
    static let checkboxSize: CGFloat = 24

    /// The underlying `CheckboxView`. `fileprivate` so the `isCheckedPublisher`
    /// extension below can read it without exposing the view publicly.
    fileprivate lazy var checkbox: CheckboxView = {
        let size = CheckboxWithLabel.checkboxSize
        return CheckboxView(frame: CGRect(origin: .zero, size: CGSize(width: size, height: size)))
    }()

    /// Label sitting next to the checkbox.
    private lazy var label = UILabel()
    /// Horizontal stack view composing checkbox + label.
    private lazy var stackView = UIStackView(arrangedSubviews: [checkbox, label])

    /// Tap anywhere on the row → toggle the underlying checkbox and emit a
    /// `.valueChanged` event. Mirrors `CheckboxView`'s own touch handling but
    /// at the compound-view level so the label area is also tappable.
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.beginTracking(touch, with: event)
        checkbox.setOn(!checkbox.on, animated: true)
        checkbox.sendActions(for: .valueChanged)
        return true
    }
}

extension CheckboxWithLabel {
    /// Applies the style and triggers internal setup. Uses `defer` so `setup()`
    /// runs *after* the label/stack have been styled — keeping setup in one
    /// place even though it depends on style being applied first.
    func apply(style: Style) {
        defer { setup() }
        label.withStyle(.checkbox) {
            $0.text(style.labelText)
                .numberOfLines(style.numberOfLines ?? 0)
        }

        stackView.withStyle(.horizontal) {
            if let alignment = style.alignment {
                $0.alignment(alignment)
            } else {
                // Heuristic: multi-line labels look better top-aligned with
                // the box; single-line should fill so they baseline-align.
                $0.alignment(style.numberOfLines == 0 ? .top : .fill)
            }
        }
    }

    /// Apply `style` (optionally customised) and return `self` for chaining.
    /// Same call shape as the other `withStyle(_:customize:)` overloads.
    @discardableResult
    func withStyle(
        _ style: Style,
        customize: ((Style) -> Style)? = nil
    ) -> CheckboxWithLabel {
        translatesAutoresizingMaskIntoConstraints = false
        let style = customize?(style) ?? style
        apply(style: style)
        return self
    }
}

// MARK: - Style + Customizing

extension CheckboxWithLabel.Style {
    /// Returns a copy of this style with `labelText` replaced.
    @discardableResult
    func text(_ text: String?) -> CheckboxWithLabel.Style {
        var style = self
        style.labelText = text
        return style
    }

    /// Returns a copy of this style with `numberOfLines` replaced.
    @discardableResult
    func numberOfLines(_ numberOfLines: Int) -> CheckboxWithLabel.Style {
        var style = self
        style.numberOfLines = numberOfLines
        return style
    }
}

// MARK: - Style Presets

extension CheckboxWithLabel.Style {
    /// Default — multi-line label, top-aligned with the checkbox.
    static var `default`: CheckboxWithLabel.Style {
        .init(numberOfLines: 0)
    }
}

// MARK: - Private Setup

private extension CheckboxWithLabel {
    /// Builds the view hierarchy and disables interaction on the inner views.
    /// User-interaction routes through the compound `UIControl` itself
    /// (`beginTracking`) so a tap on the label still toggles the checkbox.
    func setup() {
        addSubview(stackView)
        setupViews()
        setupConstraints()

        stackView.isUserInteractionEnabled = false
        label.isUserInteractionEnabled = false
    }

    /// Per-subview setup hook — only the checkbox needs configuration; the
    /// label is fully driven by `apply(style:)`.
    func setupViews() {
        setupCheckbox()
    }

    /// Pin the stack view to our edges and lock the checkbox to a fixed square.
    func setupConstraints() {
        stackView.edgesToSuperview()
        checkbox.height(CheckboxWithLabel.checkboxSize)
        checkbox.width(CheckboxWithLabel.checkboxSize)
    }

    /// Visual configuration for the checkbox — teal accent on dark background,
    /// matching the rest of the app's chrome.
    func setupCheckbox() {
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        checkbox.cornerRadius = 3
        checkbox.lineWidth = 1
        checkbox.onCheckColor = .teal
        checkbox.onFillColor = .deepBlue
        checkbox.onTintColor = .teal
        checkbox.tintColor = .teal
        checkbox.animationDuration = 0.2
    }
}

// MARK: - CheckboxWithLabel + Publishers

extension CheckboxWithLabel {
    /// Re-exports the underlying checkbox's checked-state publisher so views
    /// don't have to reach through to the compound view's internals.
    var isCheckedPublisher: AnyPublisher<Bool, Never> {
        checkbox.isCheckedPublisher
    }
}

// MARK: - CheckboxView + Publishers

extension CheckboxView {
    /// Publisher of the checkbox's checked state. Emits the *current* state
    /// immediately (so subscribers see the initial value), then forwards every
    /// `.valueChanged` event. Same RxCocoa-style pattern as
    /// `UISegmentedControl.valuePublisher`.
    var isCheckedPublisher: AnyPublisher<Bool, Never> {
        Publishers.Merge(
            Just(on),
            publisher(for: .valueChanged).map { [weak self] _ in self?.on ?? false }
        )
        .eraseToAnyPublisher()
    }
}
