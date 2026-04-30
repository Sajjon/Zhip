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

import Factory
import SingleLineControllerCore
import SingleLineControllerDIPrimitives
import TinyConstraints
import UIKit
import Validation

/// Compound view that hosts a `PincodeTextField` (the visible digit boxes
/// + invisible underlying text field) plus an error label below.
///
/// Owns the validation choreography — when the parent view's `validate(_:)`
/// is called we drive both the field's underline colours, the error label
/// text, optional input clearing, optional shake animation, and a haptic
/// notification (success/error).
public final class InputPincodeView: UIView {
    /// The underlying pincode field. `internal` so the publishers extension can
    /// reach it.
    lazy var pinField = PincodeTextField()
    /// Inline error label rendered below the field.
    private lazy var errorLabel = UILabel()
    /// Vertical stack composing field + error label.
    private lazy var stackView = UIStackView(arrangedSubviews: [pinField, errorLabel])

    /// Haptic-feedback service. Resolved via Factory so tests register a no-op.
    @Injected(\.hapticFeedback) private var hapticFeedback: HapticFeedback
    /// `true` to clear the input on `.valid`/`.empty` results — used during
    /// "choose pincode" / "confirm pincode" flows where we want a clean field
    /// after each correct entry.
    private let isClearedOnValidInput: Bool

    /// Designated initialiser.
    /// - Parameter isClearedOnValidInput: see the property above.
    init(isClearedOnValidInput: Bool = true) {
        self.isClearedOnValidInput = isClearedOnValidInput
        super.init(frame: .zero)
        setup()
    }

    /// Storyboard init — unsupported, traps to enforce programmatic-only use.
    required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }

    /// Routes a validation result through the visible UI:
    ///   - `.valid`: success haptic, clear the error label, optional input clear
    ///     (falls through to `.empty` for the shared cleanup).
    ///   - `.empty`: clear the error label, optional input clear.
    ///   - `.errorMessage`: error haptic, surface the message, shake the field
    ///     and clear input *after* the shake completes (clearing mid-shake
    ///     would feel jarring).
    func applyValidation(_ validation: AnyValidation) {
        pinField.applyValidation(validation)

        switch validation {
        case .valid:
            vibrateOnValid(); fallthrough
        case .empty:
            errorLabel.text = nil
            if isClearedOnValidInput {
                pinField.clearInput()
            }
        case let .errorMessage(errorMessage):
            vibrateOnInvalid()
            errorLabel.text = errorMessage
            shake { [weak self] in
                self?.pinField.clearInput()
            }
        }
    }
}

private extension InputPincodeView {
    /// Lays out field + error in a vertical stack and sets the error label's
    /// red, centred body style.
    func setup() {
        translatesAutoresizingMaskIntoConstraints = true
        stackView.withStyle(.default)
        addSubview(stackView)
        stackView.edgesToSuperview()
        errorLabel.withStyle(.body) {
            $0.textAlignment(.center).textColor(.bloodRed)
        }
    }

    /// Fires the system "error" haptic — sharp double-thunk feedback.
    func vibrateOnInvalid() {
        hapticFeedback.notify(.error)
    }

    /// Fires the system "success" haptic — light upward chime.
    func vibrateOnValid() {
        hapticFeedback.notify(.success)
    }
}
