// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import Foundation

/// `@objc`-callable target/action shim that forwards `UIBarButtonItem` taps
/// (and similar `UIControl.Event`-based callbacks that need a real `target`)
/// into a Combine `PassthroughSubject`.
///
/// Used by `AbstractController` to bridge UIKit's classic target/action API
/// to the project's reactive view-model inputs without scattering `@objc`
/// methods across every controller.
class AbstractTarget {
    /// Subject the `pressed()` selector pushes into. `unowned` because the
    /// owning controller (which also holds the subject) outlives this target,
    /// so a strong reference would just be redundant.
    private unowned let triggerSubject: PassthroughSubject<Void, Never>

    /// Designated initialiser — captures the subject to forward into.
    init(triggerSubject: PassthroughSubject<Void, Never>) {
        self.triggerSubject = triggerSubject
    }

    /// `@objc` entry point UIKit invokes via `#selector(AbstractTarget.pressed)`.
    /// Forwards a `Void` value through the subject.
    @objc func pressed() {
        triggerSubject.send(())
    }
}
