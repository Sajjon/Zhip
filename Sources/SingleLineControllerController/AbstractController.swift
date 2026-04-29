// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import SingleLineControllerCore
import UIKit

/// Common ancestor of every screen-level `UIViewController` in apps using SLC.
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
open class AbstractController: UIViewController {
    /// Subject fired every time the navigation-item *right* bar button is pressed.
    /// Forwarded to the ViewModel as `InputFromController.rightBarButtonTrigger`.
    public let rightBarButtonSubject = PassthroughSubject<Void, Never>()

    /// Subject fired every time the navigation-item *left* bar button is pressed.
    /// Forwarded to the ViewModel as `InputFromController.leftBarButtonTrigger`.
    public let leftBarButtonSubject = PassthroughSubject<Void, Never>()

    /// `@objc` target object UIKit invokes for the right bar button's action selector.
    /// Lazily constructed because it captures `rightBarButtonSubject`, which must be
    /// initialised first.
    public lazy var rightBarButtonAbstractTarget = AbstractTarget(triggerSubject: rightBarButtonSubject)

    /// `@objc` target object UIKit invokes for the left bar button's action selector.
    /// Lazily constructed because it captures `leftBarButtonSubject`, which must be
    /// initialised first.
    public lazy var leftBarButtonAbstractTarget = AbstractTarget(triggerSubject: leftBarButtonSubject)

    /// Default initializer forwards to `UIViewController` with the standard
    /// programmatic-only `(nibName: nil, bundle: nil)` pair.
    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    /// Designated `nibName/bundle` initializer kept available for subclasses that
    /// want to forward storyboard/Xib paths through.
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    /// Unavailable — Interface Builder is not supported. Traps to enforce the
    /// programmatic-only invariant.
    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }
}

extension AbstractController {
    /// Default `description` is the runtime class name — handy in logs to identify
    /// the concrete `SceneController<…>` specialisation without an inheritance dance.
    override open var description: String {
        "\(type(of: self))"
    }
}
