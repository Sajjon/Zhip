// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import UIKit

public extension UITextField {
    /// Binder for the placeholder text.
    var placeholderBinder: Binder<String?> {
        Binder(self) { $0.placeholder = $1 }
    }

    /// Write text from ViewModel output.
    var textBinder: Binder<String?> {
        Binder(self) { $0.text = $1 }
    }

    /// Publisher of text changes; emits the current text immediately, then
    /// forwards every change via `textDidChangeNotification`.
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
    var isEditingPublisher: AnyPublisher<Bool, Never> {
        publisher(for: .editingDidBegin).map { _ in true }
            .merge(with: publisher(for: .editingDidEnd).map { _ in false })
            .eraseToAnyPublisher()
    }

    /// Fires once each time the user finishes editing.
    var didEndEditingPublisher: AnyPublisher<Void, Never> {
        isEditingPublisher.filter { !$0 }.mapToVoid().eraseToAnyPublisher()
    }
}

public extension UITextView {
    /// Write text from ViewModel output.
    var textBinder: Binder<String> {
        Binder(self) { $0.text = $1 }
    }

    /// Fires when the text view becomes the first responder.
    var didBeginEditingPublisher: AnyPublisher<Void, Never> {
        NotificationCenter.default
            .publisher(for: UITextView.textDidBeginEditingNotification, object: self)
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    /// Publisher mirroring `UITextField.textPublisher` for text views.
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
    /// of the bottom.
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

    /// Edge-triggered variant of `isNearBottomPublisher`.
    func didScrollNearBottomPublisher(yThreshold: CGFloat = 0.98) -> AnyPublisher<Void, Never> {
        isNearBottomPublisher(yThreshold: yThreshold).filter { $0 }.mapToVoid().eraseToAnyPublisher()
    }
}
