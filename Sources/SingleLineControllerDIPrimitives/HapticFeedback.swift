// MIT License — Copyright (c) 2018-2026 Open Zesame

import UIKit

/// Abstracts over `UINotificationFeedbackGenerator`. Tests register a mock so
/// unit tests never trigger a real device vibration (on-device haptics can
/// leak across concurrent test runs and interfere with UI tests).
public protocol HapticFeedback: AnyObject {
    /// Fires a system haptic pulse of the requested `type`.
    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType)
}

/// Production `HapticFeedback` backed by `UINotificationFeedbackGenerator`.
public final class DefaultHapticFeedback: HapticFeedback {
    private let generator = UINotificationFeedbackGenerator()

    public init() {}

    public func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        generator.notificationOccurred(type)
    }
}
