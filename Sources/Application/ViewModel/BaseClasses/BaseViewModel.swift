// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation
import SingleLineControllerCore

/// Concrete base class used by every ViewModel in the app.
///
/// `BaseViewModel` fixes `FromController` to the app's standard `InputFromController`
/// and adds a `Navigator<NavigationStep>` — a `PassthroughSubject`-backed stepper
/// that coordinators subscribe to for flow navigation.
///
/// Generic parameters:
/// - `NavigationStep`: the scene's navigation enum (e.g. `WelcomeUserAction.start`).
/// - `InputFromView`: the view channel input struct nested inside the subclass.
/// - `OutputFromViewModel`: the ViewModel's output struct.
class BaseViewModel<NavigationStep, InputFromView, OutputFromViewModel>: AbstractViewModel<
    InputFromView,
    InputFromController,
    OutputFromViewModel
> {

    /// Emits navigation steps when the ViewModel calls `navigator.next(_:)`.
    /// Owned by the coordinator, which subscribes to `navigator.navigation` to
    /// drive push/pop/present transitions.
    let navigator: Navigator<NavigationStep>

    /// Designated initializer.
    ///
    /// The default `Navigator()` argument is the common case; tests may inject a
    /// custom navigator if they need to observe step emissions without going
    /// through `navigator.navigation`.
    init(navigator: Navigator<NavigationStep> = Navigator<NavigationStep>()) {
        self.navigator = navigator
    }
}

/// Retroactive `Navigating` conformance unlocks `userIntends(to:)` and other
/// convenience helpers on every `BaseViewModel`.
extension BaseViewModel: Navigating {}

