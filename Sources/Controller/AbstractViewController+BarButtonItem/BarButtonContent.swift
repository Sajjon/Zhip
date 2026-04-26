//
// MIT License
//
// Copyright (c) 2018-2026 Open Zesame (https://github.com/OpenZesame)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import UIKit

/// A description of the *content* of a navigation bar button, decoupled from the
/// `UIBarButtonItem` instance itself. Lets ViewModels emit reactive content updates
/// (text/icon/style) without holding any UIKit objects.
///
/// Convert to a real `UIBarButtonItem` via `makeBarButtonItem(target:selector:)`.
struct BarButtonContent {
    /// What is rendered inside the bar button — text, an image, or a built-in
    /// system item (which has its own preset glyph and a11y label).
    enum ButtonType {
        /// Display the associated string as the button's title.
        case text(String)
        /// Display the associated image as the button's icon.
        case image(UIImage)
        /// Use one of UIKit's standard system items (Done/Cancel/Add/...).
        case system(UIBarButtonItem.SystemItem)
    }

    /// The visual content of the button.
    let type: ButtonType
    /// Optional `UIBarButtonItem.Style` override. Ignored for `.system(_)` content
    /// (system items pick their own style). Falls back to `.plain` if nil.
    let style: UIBarButtonItem.Style?

    /// Designated initialiser. `style` defaults to `.plain` to match UIKit's
    /// default behaviour when no style is supplied.
    init(type: ButtonType, style: UIBarButtonItem.Style? = .plain) {
        self.type = type
        self.style = style
    }

    /// Convenience for text buttons. `CustomStringConvertible` lets call sites
    /// pass either a `String` directly or any value with a `description`.
    init(title: CustomStringConvertible, style: UIBarButtonItem.Style = .plain) {
        self.init(type: .text(title.description), style: style)
    }

    /// Convenience for image buttons. `ImageConvertible` lets call sites pass
    /// an asset enum case directly without resolving to `UIImage` themselves.
    init(image: ImageConvertible, style: UIBarButtonItem.Style = .plain) {
        self.init(type: .image(image.image), style: style)
    }

    /// Convenience for system buttons. No style argument because system items
    /// override the style anyway.
    init(system: UIBarButtonItem.SystemItem) {
        self.init(type: .system(system))
    }
}

// MARK: - UIBarButtonItem

extension BarButtonContent {
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
