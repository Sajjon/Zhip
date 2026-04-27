// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import SingleLineControllerCore

/// The contract every scene's root `UIView` implements to participate in the
/// reactive MVVM pipeline.
///
/// A `ViewModelled` view exposes its user-driven publishers as `inputFromView`
/// (read by `SceneController`), and binds the ViewModel's `OutputVM` back into
/// UI controls via `populate(with:)` — returning the `AnyCancellable`s so the
/// controller can retain them for the view's lifetime.
protocol ViewModelled: EmptyInitializable {
    /// The ViewModel type this view is paired with.
    associatedtype ViewModel: ViewModelType

    /// Convenience alias so conforming types can declare an inner
    /// `struct InputFromView {…}` without restating the ViewModel's type.
    typealias InputFromView = ViewModel.Input.FromView

    /// User-event publishers the ViewModel consumes (taps, text changes, toggles).
    var inputFromView: InputFromView { get }

    /// Binds the ViewModel's output publishers to UI controls. Called exactly
    /// once after `transform`. The returned cancellables are retained by the
    /// `SceneController` for the lifetime of the scene.
    func populate(with viewModel: ViewModel.OutputVM) -> [AnyCancellable]
}

extension ViewModelled {
    /// Default no-op so pure-output-less views (e.g. static welcome screens) don't
    /// need to implement `populate`.
    func populate(with _: ViewModel.OutputVM) -> [AnyCancellable] {
        []
    }
}

/// Sentinel `FromController` type used by views that don't need any controller-
/// lifecycle input — keeps the ViewModel generic parameter non-optional without
/// forcing every view to accept an unused `InputFromController`.
struct NoControllerInput {}

extension ViewModelled where ViewModel.Input.FromController == NoControllerInput {
    /// Convenience: builds the ViewModel input struct with an empty controller
    /// channel for views that don't care about lifecycle events.
    var input: ViewModel.Input {
        ViewModel.Input(fromView: inputFromView, fromController: NoControllerInput())
    }
}
