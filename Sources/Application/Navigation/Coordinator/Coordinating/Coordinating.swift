// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import UIKit

/// The contract every coordinator implements.
///
/// All extension-based helpers — modal presentation, push, replace,
/// child-coordinator stack management, debug printing — operate on this
/// protocol so any concrete coordinator gets them for free by conforming.
protocol Coordinating: AnyObject, CustomStringConvertible {
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

extension Coordinating {
    /// Default `CustomStringConvertible` impl — recursive ascii dump of the
    /// coordinator/scene tree, useful in `po self` during debugging.
    var description: String { stringRepresentation(level: 1) }
}
