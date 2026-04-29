// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import UIKit

/// Standard "no-arg, no-return" completion closure used throughout navigation.
public typealias Completion = () -> Void
/// Closure handed to navigation handlers so they can dismiss the scene they
/// were just told to navigate from. The `Bool` is the animation flag, the
/// optional inner `Completion` fires after the dismiss animation finishes.
public typealias DismissScene = (_ animatedDismiss: Bool, _ presentationCompletion: Completion?) -> Void

/// The contract every coordinator implements.
///
/// All extension-based helpers — modal presentation, push, replace,
/// child-coordinator stack management, debug printing — operate on this
/// protocol so any concrete coordinator gets them for free by conforming.
///
/// `CustomStringConvertible` is *not* a constraint here: consumers that want
/// a rich coordinator-tree dump declare conformance themselves and provide the
/// `description` (Zhip's `Coordinating+DebugPrinting.swift` does this with
/// `stringRepresentation(level:)`).
public protocol Coordinating: AnyObject {
    /// Sub-flows currently in flight. The parent appends children when starting
    /// them and removes them in `remove(childCoordinator:)` once they finish.
    var childCoordinators: [Coordinating] { get set }
    /// Subscription bag for the navigation pipelines spawned by this coordinator.
    var cancellables: Set<AnyCancellable> { get set }
    /// Builds and presents the coordinator's root scene. `didStart` fires after presentation.
    func start(didStart: Completion?)
    /// The navigation controller this coordinator operates on.
    var navigationController: UINavigationController { get }
}
