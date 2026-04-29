// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import UIKit

public extension UIControl {
    /// Binder that programmatically focuses this control on each `Void` value.
    var becomeFirstResponderBinder: Binder<Void> {
        Binder(self) { control, _ in _ = control.becomeFirstResponder() }
    }

    /// Binder driving the control's `isEnabled` state.
    var isEnabledBinder: Binder<Bool> {
        Binder(self) { $0.isEnabled = $1 }
    }

    /// Publisher fired for each `.touchUpInside` event.
    var tapPublisher: AnyPublisher<Void, Never> {
        publisher(for: .touchUpInside).eraseToAnyPublisher()
    }
}

public extension UILabel {
    /// Binder that drives the label's `text`.
    var textBinder: Binder<String?> {
        Binder(self) { $0.text = $1 }
    }
}

public extension UIButton {
    /// Returns a binder that updates the button's title for the given control state.
    func titleBinder(for state: UIControl.State) -> Binder<String?> {
        Binder(self) { button, title in
            button.setTitle(title, for: state)
        }
    }
}

public extension UISegmentedControl {
    /// Publisher of the currently-selected segment index.
    var valuePublisher: AnyPublisher<Int, Never> {
        Publishers.Merge(
            Just(selectedSegmentIndex),
            publisher(for: .valueChanged).map { [weak self] _ in self?.selectedSegmentIndex ?? 0 }
        )
        .eraseToAnyPublisher()
    }
}
