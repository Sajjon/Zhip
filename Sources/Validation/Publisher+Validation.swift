// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import SingleLineControllerCombine
import SingleLineControllerCore

/// Carrier for "what is the validation, and is the user currently editing the field?".
///
/// The view layer combines `UITextField.isEditingPublisher` with the validator's
/// output, then runs the result through `eagerValidLazyErrorTurnedToEmptyOnEdit`
/// to suppress noisy red-state error flashes mid-typing.
public struct EditingValidation {
    /// `true` while the field is the first responder.
    public let isEditing: Bool
    /// The validator's verdict for the current text.
    public let validation: AnyValidation

    /// Capture editing state + validation verdict. The view layer does the
    /// editing-state lookup and validator invocation; this carrier just
    /// bundles the pair so downstream operators can decide visibility.
    public init(isEditing: Bool, validation: AnyValidation) {
        self.isEditing = isEditing
        self.validation = validation
    }
}

public extension Publisher where Output == EditingValidation, Failure == Never {
    /// "Eager-valid, lazy-error" — show "valid" the moment the input becomes
    /// valid, but suppress error feedback while the user is still typing.
    /// Once the user commits (resigns first responder), surface the error.
    ///
    /// Optionally merges in errors from a separate publisher (e.g. tracked async
    /// errors from a use-case) that should be displayed *immediately* regardless
    /// of editing state — useful for "incorrect password" responses from the
    /// keystore decryption use case.
    func eagerValidLazyErrorTurnedToEmptyOnEdit(
        directlyDisplayErrorMessages: AnyPublisher<String, Never> = Empty().eraseToAnyPublisher()
    ) -> AnyPublisher<AnyValidation, Never> {
        let editingValidation = map { (input: EditingValidation) -> AnyValidation in
            switch (input.isEditing, input.validation) {
            // Valid: always pass through (eager-valid).
            case (_, .valid): input.validation
            // Not editing: pass through whatever (errors included) — lazy-error.
            case (false, _): input.validation
            // Editing + non-valid: hide the verdict so the user isn't yelled at mid-keystroke.
            case (true, _): .empty
            }
        }

        return directlyDisplayErrorMessages
            .map { AnyValidation.errorMessage($0) }
            .merge(with: editingValidation)
            .eraseToAnyPublisher()
    }

    /// Variant that takes typed `InputError`s and routes their `errorMessage`
    /// strings through the eager-valid/lazy-error pipeline.
    func eagerValidLazyErrorTurnedToEmptyOnEdit(
        directlyDisplayTrackedErrors trackedErrors: AnyPublisher<some InputError, Never>
    ) -> AnyPublisher<AnyValidation, Never> {
        eagerValidLazyErrorTurnedToEmptyOnEdit(
            directlyDisplayErrorMessages: trackedErrors.map(\.errorMessage).eraseToAnyPublisher()
        )
    }

    /// Convenience that pulls tracked errors directly from an `ErrorTracker`
    /// (typically the one shared with `ActivityIndicator` for a use-case call).
    /// Uses the public `ErrorTracker.compactMap` hook (defined in the
    /// `SingleLineControllerCore` package) instead of the old `asInputErrors`
    /// shim — same semantics, just sourced from the package now.
    func eagerValidLazyErrorTurnedToEmptyOnEdit(
        directlyDisplayErrorsTrackedBy errorTracker: ErrorTracker,
        mapError: @escaping (Swift.Error) -> (some InputError)?
    ) -> AnyPublisher<AnyValidation, Never> {
        eagerValidLazyErrorTurnedToEmptyOnEdit(
            directlyDisplayTrackedErrors: errorTracker.compactMap(mapError)
        )
    }
}

public extension Publisher where Failure == Never, Output: ValidationConvertible {
    /// Filters the upstream to only emit the `.errorMessage(...)` cases.
    /// Used by views that want to drive a separate error-only label.
    func onlyErrors() -> AnyPublisher<AnyValidation, Never> {
        map(\.validation)
            .compactMap { $0.isError ? $0 : nil }
            .eraseToAnyPublisher()
    }

    /// Filters the upstream to drop error cases — passes valid/empty through.
    func nonErrors() -> AnyPublisher<AnyValidation, Never> {
        map(\.validation)
            .compactMap { !$0.isError ? $0 : nil }
            .eraseToAnyPublisher()
    }
}
