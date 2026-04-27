// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine

/// One-way bridge between ViewModels (which decide what happens next) and
/// coordinators (which know how to push/pop/present).
///
/// The ViewModel calls `navigator.next(step)` to declare intent; the coordinator
/// subscribes to `navigator.navigation` to receive those steps and perform the
/// actual UIKit transitions.
final class Navigator<NavigationStep> {
    /// Internal backing subject. Exposed read-only via `navigation`.
    private let navigationSubject = PassthroughSubject<NavigationStep, Never>()

    /// Erased publisher coordinators subscribe to. Lazy so each `Navigator`
    /// produces the publisher at most once and subsequent subscriptions share it.
    lazy var navigation: AnyPublisher<NavigationStep, Never> = navigationSubject.eraseToAnyPublisher()
}

extension Navigator {
    /// Emits `step` on `navigation`. Called by ViewModels to request navigation.
    func next(_ step: NavigationStep) {
        navigationSubject.send(step)
    }
}
