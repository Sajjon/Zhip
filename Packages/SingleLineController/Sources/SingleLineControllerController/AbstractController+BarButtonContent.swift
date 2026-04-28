// MIT License — Copyright (c) 2018-2026 Open Zesame

import SingleLineControllerCore
import UIKit

public extension AbstractController {
    /// Installs `barButtonContent` as the navigation item's *right* bar button,
    /// wiring its tap to the controller's `rightBarButtonAbstractTarget` (which in
    /// turn pushes to `rightBarButtonSubject`, exposed to the ViewModel as
    /// `InputFromController.rightBarButtonTrigger`).
    func setRightBarButtonUsing(content barButtonContent: BarButtonContent) {
        let item = barButtonContent.makeBarButtonItem(
            target: rightBarButtonAbstractTarget,
            selector: #selector(AbstractTarget.pressed)
        )
        navigationItem.rightBarButtonItem = item
    }

    /// Mirror of `setRightBarButtonUsing(content:)` for the *left* bar button.
    /// See that method's documentation for the wiring chain.
    func setLeftBarButtonUsing(content barButtonContent: BarButtonContent) {
        let item = barButtonContent.makeBarButtonItem(
            target: leftBarButtonAbstractTarget,
            selector: #selector(AbstractTarget.pressed)
        )
        navigationItem.leftBarButtonItem = item
    }
}
