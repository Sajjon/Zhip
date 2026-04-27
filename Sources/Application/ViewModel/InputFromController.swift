// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import Foundation

/// The controller-lifecycle + write-back surface every `BaseViewModel` receives.
///
/// Publishers (`viewDidLoad`, bar-button triggers) flow **from** the `SceneController`
/// **into** the ViewModel. Subjects (`titleSubject`, `toastSubject`, etc.) flow the
/// other direction: the ViewModel `send`s values to drive UI the controller owns.
struct InputFromController {
    /// Fires once, right after the controller's `viewDidLoad`.
    let viewDidLoad: AnyPublisher<Void, Never>

    /// Fires every time the controller is about to appear on screen.
    let viewWillAppear: AnyPublisher<Void, Never>

    /// Fires every time the controller finishes appearing on screen.
    let viewDidAppear: AnyPublisher<Void, Never>

    /// Fires when the user taps the left navigation-bar button.
    let leftBarButtonTrigger: AnyPublisher<Void, Never>

    /// Fires when the user taps the right navigation-bar button.
    let rightBarButtonTrigger: AnyPublisher<Void, Never>

    /// The ViewModel pushes a new navigation-bar title here to update the controller.
    let titleSubject: PassthroughSubject<String, Never>

    /// The ViewModel pushes left-bar-button content (icon / title / enabled state).
    let leftBarButtonContentSubject: PassthroughSubject<BarButtonContent, Never>

    /// The ViewModel pushes right-bar-button content.
    let rightBarButtonContentSubject: PassthroughSubject<BarButtonContent, Never>

    /// The ViewModel pushes toast notifications the controller should display.
    let toastSubject: PassthroughSubject<Toast, Never>
}
