// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation

/// The central contract every ViewModel conforms to.
///
/// A ViewModel is a pure `Input → Output` transformation: it never holds mutable UI
/// state beyond its `cancellables`, and produces all of its outputs as Combine
/// publishers. `SceneController<View>` wires the `Input` together from view events
/// and lifecycle events, invokes `transform`, and hands the `OutputVM` back to the
/// view via `populate(with:)`.
public protocol ViewModelType {
    /// The combined user-action + controller-lifecycle input the ViewModel consumes.
    associatedtype Input: InputType

    /// The bag of publishers the View binds to UI controls.
    associatedtype OutputVM

    /// Runs the ViewModel's business logic.
    ///
    /// Called exactly once per instance, typically by `SceneController`. Implementations
    /// wire `input.fromView` publishers into business logic, subscribe to side-effects
    /// with `.store(in: &cancellables)`, and return an `OutputVM` full of publishers
    /// the View will bind to UI controls.
    func transform(input: Input) -> OutputVM
}
