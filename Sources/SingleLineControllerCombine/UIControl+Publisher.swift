// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import UIKit

// MARK: - UIControl event publisher

private final class WeakBox<Object: AnyObject> {
    weak var value: Object?
    init(_ value: Object) {
        self.value = value
    }
}

/// `Publisher` that emits a `Void` event each time its underlying `Control`
/// fires the bitmask of `UIControl.Event`s it was created with.
public struct UIControlPublisher<Control: UIControl>: Publisher {
    public typealias Output = Void
    public typealias Failure = Never

    private let control: WeakBox<Control>
    let events: UIControl.Event

    init(control: Control, events: UIControl.Event) {
        self.control = WeakBox(control)
        self.events = events
    }

    public func receive<S: Subscriber>(subscriber: S)
        where S.Input == Void, S.Failure == Never
    {
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

/// Per-subscription `Subscription` object. See the original Zhip source for
/// the full design rationale.
final class UIControlSubscription<S: Subscriber, Control: UIControl>: Subscription
    where S.Input == Void, S.Failure == Never {
    private var subscriber: S?
    private weak var control: Control?
    private let events: UIControl.Event

    init(subscriber: S, control: Control, events: UIControl.Event) {
        self.subscriber = subscriber
        self.control = control
        self.events = events
        control.addTarget(self, action: #selector(handleEvent), for: events)
    }

    func request(_: Subscribers.Demand) {}

    func cancel() {
        control?.removeTarget(self, action: #selector(handleEvent), for: events)
        subscriber = nil
    }

    @objc private func handleEvent() {
        _ = subscriber?.receive(())
    }
}

// MARK: - UIControl extension

public extension UIControl {
    /// Returns a `Publisher` that fires each time this control emits any of the
    /// supplied `events`. The publisher holds the control weakly.
    func publisher(for events: UIControl.Event) -> UIControlPublisher<UIControl> {
        UIControlPublisher(control: self, events: events)
    }
}
