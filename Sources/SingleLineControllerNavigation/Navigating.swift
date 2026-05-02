// MIT License — Copyright (c) 2018-2026 Open Zesame

/// Type capable of navigating. Declaring which navigation steps it can perform, by
/// declaring an `associatedtype` named `NavigationStep` which typically is a nested
/// enum.
public protocol Navigating {
    associatedtype NavigationStep
    var navigator: Navigator<NavigationStep> { get }
}
