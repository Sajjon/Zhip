// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import SingleLineControllerCombine
import UIKit

extension UITableView {
    /// Installs a footer label below the table content (or updates an existing
    /// one) with `text`. Reuses the existing `FooterView` when present so we
    /// don't constantly rebuild and reseat it on each text change.
    func setFooterLabel(text: String, height: CGFloat = 44) {
        let footerView: FooterView

        if let tableFooterView = tableFooterView as? FooterView {
            // Existing footer — just update its label below.
            footerView = tableFooterView
        } else {
            // First call: build the footer, size it once against the available
            // horizontal space (excluding safe-area insets), and seat it.
            footerView = FooterView()
            let fittingSize = CGSize(width: bounds.width - (safeAreaInsets.left + safeAreaInsets.right), height: 0)
            let size = footerView.systemLayoutSizeFitting(
                fittingSize,
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            footerView.frame = CGRect(x: 0, y: 0, width: size.width, height: height)
            tableFooterView = footerView
        }

        footerView.updateLabel(text: text)
    }
}

extension UITableView {
    /// Reactive sink — bind a `String` publisher to drive the footer label text.
    var footerLabelBinder: Binder<String> {
        Binder(self) { $0.setFooterLabel(text: $1) }
    }
}
