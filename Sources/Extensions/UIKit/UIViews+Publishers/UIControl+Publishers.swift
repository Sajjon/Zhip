// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import UIKit

extension UIControl {
    /// Binder that programmatically focuses this control on each `Void` value.
    /// Useful for "focus the next field" reactive flows.
    var becomeFirstResponderBinder: Binder<Void> {
        Binder(self) { control, _ in _ = control.becomeFirstResponder() }
    }

    /// Binder driving the control's `isEnabled` state — most commonly used to
    /// gate primary action buttons on validation results.
    var isEnabledBinder: Binder<Bool> {
        Binder(self) { $0.isEnabled = $1 }
    }

    /// Publisher fired for each `.touchUpInside` event — the canonical
    /// "tapped" signal across the app's reactive view-model pipelines.
    var tapPublisher: AnyPublisher<Void, Never> {
        publisher(for: .touchUpInside).eraseToAnyPublisher()
    }
}

extension UILabel {
    /// Binder that drives the label's `text`. Optional because labels accept
    /// `nil` (renders empty).
    var textBinder: Binder<String?> {
        Binder(self) { $0.text = $1 }
    }
}

extension UIButton {
    /// Returns a binder that updates the button's title for the given control state
    /// (e.g. `.normal`, `.disabled`).
    func titleBinder(for state: UIControl.State) -> Binder<String?> {
        Binder(self) { button, title in
            button.setTitle(title, for: state)
        }
    }
}

extension UISegmentedControl {
    /// Publisher of the currently-selected segment index.
    ///
    /// Emits the *current* index immediately (via `Just`) so subscribers see
    /// the initial value before any user interaction, then continues with each
    /// `.valueChanged` event. Mirrors the RxCocoa `controlProperty` pattern.
    var valuePublisher: AnyPublisher<Int, Never> {
        Publishers.Merge(
            Just(selectedSegmentIndex),
            publisher(for: .valueChanged).map { [weak self] _ in self?.selectedSegmentIndex ?? 0 }
        )
        .eraseToAnyPublisher()
    }
}
