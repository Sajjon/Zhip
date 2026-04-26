// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import UIKit

// MARK: - UIControl event publisher

/// Local weak-reference box (a private mirror of `Models/Weak.swift`) used to
/// avoid extending the lifetime of the `UIControl` we're observing.
private final class WeakBox<Object: AnyObject> {
    /// The weakly-held control. Becomes `nil` once the underlying control is
    /// deallocated, after which the publisher just completes immediately.
    weak var value: Object?

    /// Wraps `value` in a weak reference.
    init(_ value: Object) {
        self.value = value
    }
}

/// `Publisher` that emits a `Void` event each time its underlying `Control`
/// fires the bitmask of `UIControl.Event`s it was created with.
///
/// Standard pattern: a thin `Publisher` value that lazily constructs a
/// `UIControlSubscription` per subscriber to manage the actual `addTarget`/
/// `removeTarget` lifecycle.
public struct UIControlPublisher<Control: UIControl>: Publisher {
    public typealias Output = Void
    public typealias Failure = Never

    /// Weakly-held source control. If it's gone by subscription time the
    /// publisher completes immediately without producing any events.
    private let control: WeakBox<Control>
    /// Bitmask of UIControl events to observe (`.touchUpInside`, `.valueChanged`, …).
    let events: UIControl.Event

    init(control: Control, events: UIControl.Event) {
        self.control = WeakBox(control)
        self.events = events
    }

    /// `Publisher` conformance — produce a fresh subscription per subscriber.
    /// If the control was already deallocated, signal an immediate completion.
    public func receive<S: Subscriber>(subscriber: S)
        where S.Input == Void, S.Failure == Never {
        guard let control = control.value else {
            subscriber.receive(subscription: Subscriptions.empty)
            subscriber.receive(completion: .finished)
            return
        }
        let subscription = UIControlSubscription(
            subscriber: subscriber,
            control: control,
            events: events
        )
        subscriber.receive(subscription: subscription)
    }
}

/// Per-subscription `Subscription` object. Acts as the `@objc` target/action
/// receiver for the underlying `UIControl`, then forwards each event to its
/// subscriber as a `Void` value.
///
/// `internal` (rather than `private`) so generic specialisation visibility works
/// across the file.
final class UIControlSubscription<S: Subscriber, Control: UIControl>: Subscription
    where S.Input == Void, S.Failure == Never {

    /// Downstream subscriber. Cleared on cancel so we don't hold it alive after
    /// the subscription ends.
    private var subscriber: S?
    /// Weak ref to the control — same lifetime concern as in `WeakBox`.
    private weak var control: Control?
    /// The events bitmask we registered for; needed to undo the registration on cancel.
    private let events: UIControl.Event

    /// Stores the subscriber/control and immediately registers for the events
    /// using UIKit's classic `target/action` API.
    init(subscriber: S, control: Control, events: UIControl.Event) {
        self.subscriber = subscriber
        self.control = control
        self.events = events
        control.addTarget(self, action: #selector(handleEvent), for: events)
    }

    /// Demand is ignored — UI events arrive whenever the user produces them and
    /// we always forward exactly one value per event.
    public func request(_ demand: Subscribers.Demand) {}

    /// Tear down: remove the target/action registration and drop the subscriber
    /// reference so the chain can be deallocated.
    public func cancel() {
        control?.removeTarget(self, action: #selector(handleEvent), for: events)
        subscriber = nil
    }

    /// `@objc` entry point UIKit invokes for each control event. Forwards a
    /// `Void` value to the downstream subscriber if it is still around.
    @objc private func handleEvent() {
        _ = subscriber?.receive(())
    }
}

// MARK: - UIControl extension

public extension UIControl {
    /// Returns a `Publisher` that fires each time this control emits any of the
    /// supplied `events`. The publisher holds the control weakly, so it does
    /// not extend the control's lifetime.
    func publisher(for events: UIControl.Event) -> UIControlPublisher<UIControl> {
        UIControlPublisher(control: self, events: events)
    }
}
