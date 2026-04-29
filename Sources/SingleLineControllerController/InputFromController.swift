// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import Foundation

/// The controller-lifecycle + write-back surface every `BaseViewModel` receives.
///
/// Publishers (`viewDidLoad`, bar-button triggers) flow **from** the `SceneController`
/// **into** the ViewModel. Subjects (`titleSubject`, `toastSubject`, etc.) flow the
/// other direction: the ViewModel `send`s values to drive UI the controller owns.
public struct InputFromController {
    /// Fires once, right after the controller's `viewDidLoad`.
    public let viewDidLoad: AnyPublisher<Void, Never>

    /// Fires every time the controller is about to appear on screen.
    public let viewWillAppear: AnyPublisher<Void, Never>

    /// Fires every time the controller finishes appearing on screen.
    public let viewDidAppear: AnyPublisher<Void, Never>

    /// Fires when the user taps the left navigation-bar button.
    public let leftBarButtonTrigger: AnyPublisher<Void, Never>

    /// Fires when the user taps the right navigation-bar button.
    public let rightBarButtonTrigger: AnyPublisher<Void, Never>

    /// The ViewModel pushes a new navigation-bar title here to update the controller.
    public let titleSubject: PassthroughSubject<String, Never>

    /// The ViewModel pushes left-bar-button content (icon / title / enabled state).
    public let leftBarButtonContentSubject: PassthroughSubject<BarButtonContent, Never>

    /// The ViewModel pushes right-bar-button content.
    public let rightBarButtonContentSubject: PassthroughSubject<BarButtonContent, Never>

    /// The ViewModel pushes toast notifications the controller should display.
    public let toastSubject: PassthroughSubject<Toast, Never>

    /// Memberwise initialiser — public so `SceneController` (or test fakes) can
    /// build the struct from the right side of the package boundary.
    public init(
        viewDidLoad: AnyPublisher<Void, Never>,
        viewWillAppear: AnyPublisher<Void, Never>,
        viewDidAppear: AnyPublisher<Void, Never>,
        leftBarButtonTrigger: AnyPublisher<Void, Never>,
        rightBarButtonTrigger: AnyPublisher<Void, Never>,
        titleSubject: PassthroughSubject<String, Never>,
        leftBarButtonContentSubject: PassthroughSubject<BarButtonContent, Never>,
        rightBarButtonContentSubject: PassthroughSubject<BarButtonContent, Never>,
        toastSubject: PassthroughSubject<Toast, Never>
    ) {
        self.viewDidLoad = viewDidLoad
        self.viewWillAppear = viewWillAppear
        self.viewDidAppear = viewDidAppear
        self.leftBarButtonTrigger = leftBarButtonTrigger
        self.rightBarButtonTrigger = rightBarButtonTrigger
        self.titleSubject = titleSubject
        self.leftBarButtonContentSubject = leftBarButtonContentSubject
        self.rightBarButtonContentSubject = rightBarButtonContentSubject
        self.toastSubject = toastSubject
    }
}
