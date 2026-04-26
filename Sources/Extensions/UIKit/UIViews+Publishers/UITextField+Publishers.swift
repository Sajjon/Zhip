// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import UIKit

extension UITextField {
    /// Binder for the placeholder text — driven from the ViewModel so the
    /// placeholder can interpolate dynamic values (e.g. minimum lengths).
    var placeholderBinder: Binder<String?> {
        Binder(self) { $0.placeholder = $1 }
    }

    /// Write text from ViewModel output.
    var textBinder: Binder<String?> {
        Binder(self) { $0.text = $1 }
    }

    /// Publisher of text changes; use in `inputFromView`.
    ///
    /// Emits the current text *immediately* (via `Just(text)`) so subscribers
    /// see the initial value, then forwards every change via the
    /// `textDidChangeNotification`. The notification approach catches *all*
    /// edits including programmatic ones, unlike `.editingChanged` which only
    /// fires on user interaction.
    var textPublisher: AnyPublisher<String?, Never> {
        Publishers.Merge(
            Just(text),
            NotificationCenter.default
                .publisher(for: UITextField.textDidChangeNotification, object: self)
                .map { ($0.object as? UITextField)?.text }
        )
        .eraseToAnyPublisher()
    }

    /// `true` while the field is the first responder, `false` after it resigns.
    /// Built from the two control events rather than via `isFirstResponder`
    /// polling so we get a real reactive stream.
    var isEditingPublisher: AnyPublisher<Bool, Never> {
        publisher(for: .editingDidBegin).map { _ in true }
            .merge(with: publisher(for: .editingDidEnd).map { _ in false })
            .eraseToAnyPublisher()
    }

    /// Fires once each time the user finishes editing (resigns first responder).
    /// Just sugar over `isEditingPublisher.filter(!).mapToVoid()`.
    var didEndEditingPublisher: AnyPublisher<Void, Never> {
        isEditingPublisher.filter { !$0 }.mapToVoid().eraseToAnyPublisher()
    }
}

extension UITextView {
    /// Write text from ViewModel output.
    var textBinder: Binder<String> {
        Binder(self) { $0.text = $1 }
    }

    /// Fires when the text view becomes the first responder.
    /// Notification-based (rather than control-event-based) because
    /// `UITextView` does not inherit from `UIControl`.
    var didBeginEditingPublisher: AnyPublisher<Void, Never> {
        NotificationCenter.default
            .publisher(for: UITextView.textDidBeginEditingNotification, object: self)
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    /// Publisher mirroring `UITextField.textPublisher` for text views — emits
    /// the current contents immediately, then forwards each change notification.
    var textPublisher: AnyPublisher<String?, Never> {
        Publishers.Merge(
            Just(text),
            NotificationCenter.default
                .publisher(for: UITextView.textDidChangeNotification, object: self)
                .map { ($0.object as? UITextView)?.text }
        )
        .eraseToAnyPublisher()
    }

    /// `true`/`false` editing-state publisher for text views.
    /// Same shape as the field equivalent, but built from notifications.
    var isEditingPublisher: AnyPublisher<Bool, Never> {
        NotificationCenter.default
            .publisher(for: UITextView.textDidBeginEditingNotification, object: self)
            .map { _ in true }
            .merge(
                with: NotificationCenter.default
                    .publisher(for: UITextView.textDidEndEditingNotification, object: self)
                    .map { _ in false }
            )
            .eraseToAnyPublisher()
    }

    /// `true` whenever the text view is scrolled to within `yThreshold * excess`
    /// of the bottom. Used by the legal/ToS scenes to decide when to enable
    /// the "I have read this" button — only after the user has actually
    /// scrolled through the content.
    ///
    /// Shorter-than-viewport content trivially satisfies the condition (no
    /// scrolling required).
    func isNearBottomPublisher(yThreshold: CGFloat = 0.98) -> AnyPublisher<Bool, Never> {
        publisher(for: \.contentOffset)
            .map { [weak self] _ -> Bool in
                guard let self else { return false }
                let excess = self.contentSize.height - self.frame.height
                guard excess > 0 else { return true }
                return self.contentOffset.y >= yThreshold * excess
            }
            .eraseToAnyPublisher()
    }

    /// Edge-triggered variant of `isNearBottomPublisher`. Fires once each time
    /// the threshold is crossed; sugar for `.filter { $0 }.mapToVoid()`.
    func didScrollNearBottomPublisher(yThreshold: CGFloat = 0.98) -> AnyPublisher<Void, Never> {
        isNearBottomPublisher(yThreshold: yThreshold).filter { $0 }.mapToVoid().eraseToAnyPublisher()
    }
}
