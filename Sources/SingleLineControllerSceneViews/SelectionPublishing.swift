// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import UIKit

/// Marker protocol that table-view subclasses adopt to expose a reactive
/// selection stream. Class-bound (`AnyObject`) so it composes with
/// `UITableView` subclasses without requiring `where Self: UIView` clutter.
///
/// Views that want `UITableView.itemSelectedPublisher` must conform to this.
public protocol SelectionPublishing: AnyObject {
    /// Emits each `IndexPath` selected by the user.
    var selectionPublisher: AnyPublisher<IndexPath, Never> { get }
}

public extension UITableView {
    /// Publisher of selected row indices.
    ///
    /// Forwards to whichever `SelectionPublishing` subclass actually implements
    /// the publisher (project-specific subclasses like `SingleCellTypeTableView`).
    /// A plain `UITableView` that doesn't conform yields an empty publisher —
    /// graceful degradation rather than trapping, so misuse surfaces as
    /// "no taps observed" rather than crashing the app.
    var itemSelectedPublisher: AnyPublisher<IndexPath, Never> {
        guard let selectableTable = self as? SelectionPublishing else {
            return Empty().eraseToAnyPublisher()
        }
        return selectableTable.selectionPublisher
    }
}
