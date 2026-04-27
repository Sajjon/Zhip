// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import SingleLineControllerCore
import UIKit

/// Common ancestor of every screen-level `UIViewController` in the app.
///
/// Owns the bar-button-tap pipelines that `SceneController` exposes to view-models
/// through `InputFromController`. Concretely:
///   * `…BarButtonSubject` — the publisher side, fired when the bar button is pressed.
///   * `…BarButtonAbstractTarget` — the `@objc` target/action bridge that UIKit
///     can call as a selector and that internally pushes `()` into the matching subject.
///
/// Splitting the two halves like this lets us hand UIKit a real `target/action` pair
/// (which it requires) while presenting the ViewModel layer with a clean Combine
/// publisher.
class AbstractController: UIViewController {
    /// Subject fired every time the navigation-item *right* bar button is pressed.
    /// Forwarded to the ViewModel as `InputFromController.rightBarButtonTrigger`.
    let rightBarButtonSubject = PassthroughSubject<Void, Never>()

    /// Subject fired every time the navigation-item *left* bar button is pressed.
    /// Forwarded to the ViewModel as `InputFromController.leftBarButtonTrigger`.
    let leftBarButtonSubject = PassthroughSubject<Void, Never>()

    /// `@objc` target object UIKit invokes for the right bar button's action selector.
    /// Lazily constructed because it captures `rightBarButtonSubject`, which must be
    /// initialised first.
    lazy var rightBarButtonAbstractTarget = AbstractTarget(triggerSubject: rightBarButtonSubject)

    /// `@objc` target object UIKit invokes for the left bar button's action selector.
    /// Lazily constructed because it captures `leftBarButtonSubject`, which must be
    /// initialised first.
    lazy var leftBarButtonAbstractTarget = AbstractTarget(triggerSubject: leftBarButtonSubject)
}

extension AbstractController {
    /// Default `description` is the runtime class name — handy in logs to identify
    /// the concrete `SceneController<…>` specialisation without an inheritance dance.
    override var description: String {
        "\(type(of: self))"
    }
}
