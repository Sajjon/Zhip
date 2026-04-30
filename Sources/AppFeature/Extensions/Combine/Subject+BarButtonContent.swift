// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import Foundation
import SingleLineControllerController

/// Convenience for ViewModels driving the bar-button-content subjects on
/// `InputFromController` (`leftBarButtonContentSubject`, `rightBarButtonContentSubject`).
///
/// Lets call sites push a predefined `BarButton` (skip / cancel / done) without
/// reaching into `.content` themselves — minor ergonomics that keeps the
/// `transform(input:)` bodies easier to scan.
extension PassthroughSubject where Output == BarButtonContent, Failure == Never {
    /// Sends the materialised `BarButtonContent` for the given predefined `BarButton`.
    func onBarButton(_ predefined: BarButton) {
        send(predefined.content)
    }
}
