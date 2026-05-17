// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import Foundation
import NanoViewControllerController
import NanoViewControllerCore
import NanoViewControllerNavigation

/// Concrete base class used by every ViewModel in the app.
///
/// Adapter over the new `AbstractViewModel<FromView, Publishers, NavigationStep>`
/// shape that keeps Zhip's older ergonomics intact:
///
/// * `cancellables: Set<AnyCancellable>` — a stored bag subclasses can
///   `.store(in: &cancellables)` into inside `transform(input:)`, instead of
///   funneling every subscription through `Output`'s `@BindingsBuilder` block.
///   Lifetime is fine because `NanoViewController` retains the ViewModel for
///   the lifetime of the scene.
/// * `navigator: Navigator<NavigationStep>` — a stored stepper subclasses
///   call via `userIntends(to:)`. Its publisher is handed to the returned
///   `Output(navigation:)`, so the controller wires it through to the
///   coordinator without ViewModel-side knowledge of the navigation transport.
///
/// Generic parameters (preserved positional order from the previous shape so
/// subclasses migrate with a single rename of the third slot from `Output`
/// to `Publishers`):
///
/// - `NavigationStep`: the scene's navigation enum (e.g. `WelcomeUserAction`).
///   `Sendable` is required by the underlying ``AbstractViewModel`` so the
///   navigation step can cross actor boundaries when a `Navigator.next(_:)`
///   call originates off-main.
/// - `InputFromView`: the view channel input struct nested inside the subclass.
/// - `Publishers`: the ViewModel's publisher-bag struct the view binds in
///   `populate(with:)`. Previously named `Output` per-subclass; renamed for
///   clarity (the wrapper carrying it is `Output<Publishers, NavigationStep>`).
public class BaseViewModel<
    NavigationStep: Sendable,
    InputFromView,
    Publishers
>: AbstractViewModel<InputFromView, Publishers, NavigationStep> {
    /// Subscriptions started inside `transform(input:)` that must outlive the
    /// call. Retained for the ViewModel's lifetime, which equals the
    /// scene-controller's lifetime.
    public var cancellables = Set<AnyCancellable>()

    /// Emits navigation steps when the ViewModel calls `navigator.next(_:)`.
    /// Owned by the coordinator, which subscribes to `navigator.navigation`
    /// (forwarded by `NanoViewController.navigation`) to drive push/pop/present
    /// transitions.
    public let navigator: Navigator<NavigationStep>

    /// Designated initializer.
    ///
    /// The default `Navigator()` argument is the common case; tests may inject
    /// a custom navigator if they need to observe step emissions without going
    /// through `navigator.navigation`.
    public init(navigator: Navigator<NavigationStep> = Navigator<NavigationStep>()) {
        self.navigator = navigator
        super.init()
    }
}

/// Retroactive `Navigating` conformance unlocks `userIntends(to:)` and other
/// convenience helpers on every `BaseViewModel`.
extension BaseViewModel: Navigating {}
