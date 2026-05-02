// MIT License — Copyright (c) 2018-2026 Open Zesame

import UIKit

/// A description of the *content* of a navigation bar button, decoupled from the
/// `UIBarButtonItem` instance itself. Lets ViewModels emit reactive content updates
/// (text/icon/style) without holding any UIKit objects.
///
/// Convert to a real `UIBarButtonItem` via `makeBarButtonItem(target:selector:)`.
public struct BarButtonContent {
    /// What is rendered inside the bar button — text, an image, or a built-in
    /// system item (which has its own preset glyph and a11y label).
    public enum ButtonType {
        /// Display the associated string as the button's title.
        case text(String)
        /// Display the associated image as the button's icon.
        case image(UIImage)
        /// Use one of UIKit's standard system items (Done/Cancel/Add/...).
        case system(UIBarButtonItem.SystemItem)
    }

    /// The visual content of the button.
    public let type: ButtonType
    /// Optional `UIBarButtonItem.Style` override. Ignored for `.system(_)` content
    /// (system items pick their own style). Falls back to `.plain` if nil.
    public let style: UIBarButtonItem.Style?

    /// Designated initialiser. `style` defaults to `.plain` to match UIKit's
    /// default behaviour when no style is supplied.
    public init(type: ButtonType, style: UIBarButtonItem.Style? = .plain) {
        self.type = type
        self.style = style
    }

    /// Convenience for text buttons. `CustomStringConvertible` lets call sites
    /// pass either a `String` directly or any value with a `description`.
    public init(title: CustomStringConvertible, style: UIBarButtonItem.Style = .plain) {
        self.init(type: .text(title.description), style: style)
    }

    /// Convenience for image buttons.
    public init(image: UIImage, style: UIBarButtonItem.Style = .plain) {
        self.init(type: .image(image), style: style)
    }

    /// Convenience for system buttons. No style argument because system items
    /// override the style anyway.
    public init(system: UIBarButtonItem.SystemItem) {
        self.init(type: .system(system))
    }
}

// MARK: - UIBarButtonItem

public extension BarButtonContent {
    /// Materialises this content description into a real `UIBarButtonItem`,
    /// wired to the supplied `target`/`selector` for tap handling.
    ///
    /// Style coalesces to `.plain` for non-system items; system items hand the
    /// raw `SystemItem` to the matching `UIBarButtonItem` initialiser, which
    /// already encodes its own visual style.
    func makeBarButtonItem(target: AnyObject?, selector: Selector) -> UIBarButtonItem {
        switch type {
        case let .image(image): UIBarButtonItem(image: image, style: style ?? .plain, target: target, action: selector)
        case let .text(text): UIBarButtonItem(title: text, style: style ?? .plain, target: target, action: selector)
        case let .system(system): UIBarButtonItem(barButtonSystemItem: system, target: target, action: selector)
        }
    }
}
