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
import NanoViewControllerCombine
import NanoViewControllerCore
import UIKit
import Validation

/// Pincode entry field — an invisible `UITextField` (zero-coloured text and
/// caret) overlaid by a row of `DigitView` "presentation" cells.
///
/// The text field captures the keyboard input but doesn't render anything
/// itself; the visible UI is `Presentation`, a horizontal stack view of
/// `DigitView`s that mirror the typed characters. This split lets us reuse
/// UIKit's secure-text entry plumbing while keeping full visual control.
public final class PincodeTextField: UITextField {
    /// Disable system edit-menu actions (paste/copy/cut/select/delete).
    /// The pincode must be entered character-by-character by the user — pasting
    /// would defeat the security model and copy would leak it to the pasteboard.
    /// creds: https://stackoverflow.com/a/44701936/1311272
    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
        case #selector(UIResponderStandardEditActions.paste(_:)),
             #selector(UIResponderStandardEditActions.select(_:)),
             #selector(UIResponderStandardEditActions.selectAll(_:)),
             #selector(UIResponderStandardEditActions.copy(_:)),
             #selector(UIResponderStandardEditActions.cut(_:)),
             #selector(UIResponderStandardEditActions.delete(_:)):
            false
        default:
            super.canPerformAction(action, withSender: sender)
        }
    }

    /// Disable the long-press magnifier. Triggered before any gesture
    /// recogniser is attached so even system-installed ones get neutered.
    /// creds: https://stackoverflow.com/a/10641203/1311272
    override public func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        // Prevent long press to show the magnifying glass
        if gestureRecognizer is UILongPressGestureRecognizer {
            gestureRecognizer.isEnabled = false
        }

        super.addGestureRecognizer(gestureRecognizer)
    }

    /// Belt-and-braces: even if some long-press recogniser slipped past
    /// `addGestureRecognizer`, refuse to let it begin tracking.
    override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UILongPressGestureRecognizer, !gestureRecognizer.delaysTouchesEnded {
            return false
        }
        return true
    }

    /// Forwards a validation result to the presentation so the underline
    /// colours reflect the current state.
    /// Named `applyValidation` to avoid clashing with
    /// `UIResponder.validate(_ command: UICommand)`.
    func applyValidation(_ validation: AnyValidation) {
        presentation.applyValidation(validation)
    }

    /// The visible row of digit cells.
    private let presentation: Presentation
    /// Delegate that limits keystrokes to digits and the configured length.
    private lazy var textFieldDelegate = TextFieldDelegate(type: .number, maxLength: pincodeLength)

    /// Pincode length — derived from the presentation so both stay in sync.
    private var pincodeLength: Int {
        presentation.length
    }

    /// Combine subscriptions kept alive for the field's lifetime (text→digits sink).
    private var cancellables = Set<AnyCancellable>()

    /// Internal subject the field pushes into on each digit change.
    /// `fileprivate` so the public `pincodePublisher` can wrap it.
    fileprivate var pincodeSubject = PassthroughSubject<Pincode?, Never>()

    /// Publisher of the parsed pincode — `nil` while in progress, populated
    /// once `pincodeLength` digits have been entered.
    ///
    /// `removeDuplicates` is load-bearing: we use `viewWillAppear` as a hook to
    /// re-focus the field, which can re-emit the previously-saved pincode. If
    /// the parent scene reacts by presenting an alert, dismissing the alert
    /// triggers another `viewWillAppear`, which re-emits, which re-presents…
    /// `removeDuplicates` breaks the loop.
    lazy var pincodePublisher: AnyPublisher<Pincode?, Never> = pincodeSubject
        // Calling `removeDuplicates` really is quite important, since it fixes potential bugs where
        // we use `UIViewController.viewWillAppear` as a trigger for invoking `PincodeTextField.becomeFirstResponder`
        // If we have logic presenting some alert when a pincode was removed, dismissing said alert would cause
        // `viewWillAppear` to be called resulting in `becomeFirstResponder` which would emit the same Pincode,
        // which might result in the same alert being presented.
        .removeDuplicates()
        .eraseToAnyPublisher()

    // MARK: - Initialization

    /// Designated initialiser.
    /// - Parameters:
    ///   - height: Field height (also drives glyph size via `DigitView` content).
    ///   - widthOfDigitView: Width of each digit cell.
    ///   - pincodeLength: How many digits the pincode contains. Defaults to
    ///     `Pincode.length` so both the model and view stay in sync via one
    ///     constant.
    init(height: CGFloat = 80, widthOfDigitView: CGFloat = 40, pincodeLength: Int = Pincode.length) {
        presentation = Presentation(length: pincodeLength, widthOfDigitView: widthOfDigitView)
        super.init(frame: .zero)
        setup(height: height)
    }

    /// Storyboard init — unsupported, traps to enforce programmatic-only use.
    required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }

    /// Programmatically sets the pincode (or clears it on `nil`). Used to
    /// pre-fill the field in tests and after model restoration.
    func setPincode(_ pincode: Pincode?) {
        presentation.setPincode(pincode?.digits ?? [])
    }

    /// Clears both the visible cells and the underlying text field text. Used
    /// after a successful submission or after a shake-on-error animation.
    func clearInput() {
        setPincode(nil)
        text = nil
    }
}

private extension PincodeTextField {
    /// Lays out the (invisible) text field and overlays the visible
    /// presentation. Wires the text-change publisher to `setDigits(string:)`
    /// so each keystroke pushes through to the visible cells *and* the
    /// `pincodeSubject`.
    func setup(height: CGFloat) {
        translatesAutoresizingMaskIntoConstraints = false

        self.height(height)
        keyboardType = .numberPad
        isSecureTextEntry = true
        textColor = .clear
        tintColor = .clear
        delegate = textFieldDelegate

        textPublisher
            .sink { [weak self] in
                guard let self else { return }
                setDigits(string: $0)
            }
            .store(in: &cancellables)

        addSubview(presentation)
        presentation.edgesToSuperview()
    }

    /// String → `[Digit]` parser. `nil`/empty clears the cells; longer-than-
    /// `pincodeLength` strings are silently ignored (the delegate would have
    /// rejected the keystroke, so this is defensive). Anything that survives
    /// length-checking but contains a non-digit character is a delegate bug —
    /// we crash loudly to surface it.
    func setDigits(string: String?) {
        guard let string, !string.isEmpty else {
            return setDigits([])
        }

        guard string.count <= pincodeLength else {
            return
        }

        guard
            case let digits = string.map(String.init).compactMap(Digit.init),
            digits.count == string.count
        else {
            incorrectImplementation(
                "Did you forget to protect against pasting of non numerical strings into the input field?"
            )
        }
        setDigits(digits)
    }

    /// `[Digit]` → cell update + subject emit. Uses `defer` so the subject
    /// always sees the new value, even when we early-return from the length
    /// guard (subscriber receives `try? Pincode(digits:)` which will be `nil`
    /// for incomplete sequences).
    func setDigits(_ digits: [Digit]) {
        defer { pincodeSubject.send(try? Pincode(digits: digits)) }
        guard digits.count <= pincodeLength else {
            return
        }
        presentation.setPincode(digits)
    }
}

private extension PincodeTextField.Presentation {
    /// Maps `AnyValidation` cases to the corresponding underline colour.
    /// `.valid` and `.empty` both render as the resting "valid" colour;
    /// `.errorMessage` switches every cell to red.
    func applyValidation(_ validation: AnyValidation) {
        switch validation {
        case .empty, .valid:
            colorUnderlineViews(with: AnyValidation.Color.validWithoutRemark)
        case .errorMessage:
            colorUnderlineViews(with: AnyValidation.Color.error)
        }
    }
}

extension String {
    /// `true` if this string contains a single backspace character. Used by
    /// `TextFieldDelegate` to always allow deletion regardless of validation
    /// rules. Implementation note: compares the first byte of the UTF-8
    /// encoding via `strcmp` to avoid Swift-level character iteration costs
    /// in the hot keystroke path.
    var isBackspace: Bool {
        let char = cString(using: String.Encoding.utf8)!
        return strcmp(char, "\\b") == -92
    }
}
