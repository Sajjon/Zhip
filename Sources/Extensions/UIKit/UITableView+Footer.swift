// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
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

    /// Publisher of selected row indices.
    ///
    /// Forwards to whichever `SelectionPublishing` subclass actually implements
    /// the publisher (project-specific subclasses like `SingleCellTypeTableView`).
    /// A plain `UITableView` cannot satisfy it on its own — using this on a
    /// non-conforming table is a programming error and yields an empty publisher
    /// after an `assertionFailure` in DEBUG.
    var itemSelectedPublisher: AnyPublisher<IndexPath, Never> {
        guard let selectableTable = self as? SelectionPublishing else {
            assertionFailure("UITableView must adopt SelectionPublishing to expose itemSelectedPublisher")
            return Empty().eraseToAnyPublisher()
        }
        return selectableTable.selectionPublisher
    }
}

/// Marker protocol that the project's table-view subclasses adopt to expose a
/// reactive selection stream. Class-bound (`AnyObject`) so it composes with
/// `UITableView` subclasses without requiring `where Self: UIView` clutter.
///
/// Views that want `itemSelectedPublisher` must conform to this.
protocol SelectionPublishing: AnyObject {
    /// Emits each `IndexPath` selected by the user.
    var selectionPublisher: AnyPublisher<IndexPath, Never> { get }
}
