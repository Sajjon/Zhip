// MIT License — Copyright (c) 2018-2026 Open Zesame

import Foundation

/// A ViewModel's combined input contract.
///
/// Every `ViewModelType` takes one `Input`. The `Input` is split into two channels:
/// `fromView` carries user-intent events (taps, text, toggles), and `fromController`
/// carries lifecycle events and write-back subjects (title, toasts, bar-button
/// updates). `AbstractViewModel.Input` provides the conforming implementation.
public protocol InputType {

    /// The view-driven publishers — taps, text, toggle state, etc.
    associatedtype FromView

    /// The controller-driven publishers — `viewDidLoad`, navigation-bar taps, plus
    /// the write-back subjects the ViewModel uses to push title / toast updates.
    associatedtype FromController

    /// The view channel.
    var fromView: FromView { get }

    /// The controller channel.
    var fromController: FromController { get }

    /// Designated initializer. `SceneController` constructs this struct on the
    /// ViewModel's behalf by combining the `View.inputFromView` property with the
    /// lifecycle-derived `InputFromController` it builds itself.
    init(fromView: FromView, fromController: FromController)
}
