// MIT License — Copyright (c) 2018-2026 Open Zesame

import UIKit

/// Opt-in protocol for views that produce their own content view (typically a
/// composed `UIStackView`). Used by container views like
/// `BaseScrollableStackViewOwner` to ask the conforming subclass: "what goes
/// inside?" — i.e. to obtain the seat that goes inside the scroll view.
public protocol ContentViewProvider {
    /// Construct and return the content view to seat inside the container.
    /// Called once during composition; the returned view is owned by the caller.
    func makeContentView() -> UIView
}
