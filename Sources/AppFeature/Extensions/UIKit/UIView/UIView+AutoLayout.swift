//
// MIT License
//
// Copyright (c) 2018-2026 Alexander Cyon (https://github.com/sajjon)
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

// In-house replacements for the small `TinyConstraints` API surface the app
// actually uses. Each helper:
//   1. Sets `translatesAutoresizingMaskIntoConstraints = false`.
//   2. Builds + activates the matching `NSLayoutConstraint`(s).
//   3. Returns the activated constraint(s) so callers can store / mutate them
//      later if they need to (most don't).
//
// `*ToSuperview` calls assert a non-nil superview — they're meant to be called
// after the view has been added to its parent, which is the existing pattern
// at every call site.

public extension UIView {
    /// Pins all four edges to the superview. Optional `insets` shrinks the
    /// pinned area inward (positive = padding).
    @discardableResult
    func edgesToSuperview(insets: UIEdgeInsets = .zero) -> [NSLayoutConstraint] {
        let parent = requireSuperview()
        translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            topAnchor.constraint(equalTo: parent.topAnchor, constant: insets.top),
            bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -insets.bottom),
            leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -insets.right),
        ]
        NSLayoutConstraint.activate(constraints)
        return constraints
    }

    /// Centers both X and Y on the superview.
    @discardableResult
    func centerInSuperview() -> [NSLayoutConstraint] {
        [centerXToSuperview(), centerYToSuperview()]
    }

    /// Aligns centerX to the superview's centerX (or safe-area centerX).
    @discardableResult
    func centerXToSuperview(offset: CGFloat = 0, usingSafeArea: Bool = false) -> NSLayoutConstraint {
        let parent = requireSuperview()
        translatesAutoresizingMaskIntoConstraints = false
        let anchor = usingSafeArea ? parent.safeAreaLayoutGuide.centerXAnchor : parent.centerXAnchor
        let constraint = centerXAnchor.constraint(equalTo: anchor, constant: offset)
        constraint.isActive = true
        return constraint
    }

    /// Aligns centerY to the superview's centerY (or safe-area centerY).
    @discardableResult
    func centerYToSuperview(offset: CGFloat = 0, usingSafeArea: Bool = false) -> NSLayoutConstraint {
        let parent = requireSuperview()
        translatesAutoresizingMaskIntoConstraints = false
        let anchor = usingSafeArea ? parent.safeAreaLayoutGuide.centerYAnchor : parent.centerYAnchor
        let constraint = centerYAnchor.constraint(equalTo: anchor, constant: offset)
        constraint.isActive = true
        return constraint
    }

    /// Pins top to the superview's top (or safe-area top).
    @discardableResult
    func topToSuperview(offset: CGFloat = 0, usingSafeArea: Bool = false) -> NSLayoutConstraint {
        let parent = requireSuperview()
        translatesAutoresizingMaskIntoConstraints = false
        let anchor = usingSafeArea ? parent.safeAreaLayoutGuide.topAnchor : parent.topAnchor
        let constraint = topAnchor.constraint(equalTo: anchor, constant: offset)
        constraint.isActive = true
        return constraint
    }

    /// Pins bottom to the superview's bottom. `offset` is applied directly —
    /// pass a negative value to inset (e.g. `bottomToSuperview(offset: -10)`).
    @discardableResult
    func bottomToSuperview(offset: CGFloat = 0, usingSafeArea: Bool = false) -> NSLayoutConstraint {
        let parent = requireSuperview()
        translatesAutoresizingMaskIntoConstraints = false
        let anchor = usingSafeArea ? parent.safeAreaLayoutGuide.bottomAnchor : parent.bottomAnchor
        let constraint = bottomAnchor.constraint(equalTo: anchor, constant: offset)
        constraint.isActive = true
        return constraint
    }

    /// Pins leading to the superview's leading (RTL-aware).
    @discardableResult
    func leadingToSuperview(offset: CGFloat = 0, usingSafeArea: Bool = false) -> NSLayoutConstraint {
        let parent = requireSuperview()
        translatesAutoresizingMaskIntoConstraints = false
        let anchor = usingSafeArea ? parent.safeAreaLayoutGuide.leadingAnchor : parent.leadingAnchor
        let constraint = leadingAnchor.constraint(equalTo: anchor, constant: offset)
        constraint.isActive = true
        return constraint
    }

    /// Pins trailing to the superview's trailing (RTL-aware).
    @discardableResult
    func trailingToSuperview(offset: CGFloat = 0, usingSafeArea: Bool = false) -> NSLayoutConstraint {
        let parent = requireSuperview()
        translatesAutoresizingMaskIntoConstraints = false
        let anchor = usingSafeArea ? parent.safeAreaLayoutGuide.trailingAnchor : parent.trailingAnchor
        let constraint = trailingAnchor.constraint(equalTo: anchor, constant: offset)
        constraint.isActive = true
        return constraint
    }

    /// Pins left edge to the superview's left edge (LTR — use `leadingToSuperview`
    /// for RTL-aware layouts).
    @discardableResult
    func leftToSuperview(offset: CGFloat = 0, usingSafeArea: Bool = false) -> NSLayoutConstraint {
        let parent = requireSuperview()
        translatesAutoresizingMaskIntoConstraints = false
        let anchor = usingSafeArea ? parent.safeAreaLayoutGuide.leftAnchor : parent.leftAnchor
        let constraint = leftAnchor.constraint(equalTo: anchor, constant: offset)
        constraint.isActive = true
        return constraint
    }

    /// Pins right edge to the superview's right edge (LTR — use `trailingToSuperview`
    /// for RTL-aware layouts).
    @discardableResult
    func rightToSuperview(offset: CGFloat = 0, usingSafeArea: Bool = false) -> NSLayoutConstraint {
        let parent = requireSuperview()
        translatesAutoresizingMaskIntoConstraints = false
        let anchor = usingSafeArea ? parent.safeAreaLayoutGuide.rightAnchor : parent.rightAnchor
        let constraint = rightAnchor.constraint(equalTo: anchor, constant: offset)
        constraint.isActive = true
        return constraint
    }

    /// Matches this view's height to the superview's height.
    @discardableResult
    func heightToSuperview() -> NSLayoutConstraint {
        let parent = requireSuperview()
        translatesAutoresizingMaskIntoConstraints = false
        let constraint = heightAnchor.constraint(equalTo: parent.heightAnchor)
        constraint.isActive = true
        return constraint
    }

    /// Pins the view to a fixed height. Optional `priority` lets callers
    /// downgrade the constraint so it can be broken under content pressure.
    @discardableResult
    func height(_ value: CGFloat, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let constraint = heightAnchor.constraint(equalToConstant: value)
        constraint.priority = priority
        constraint.isActive = true
        return constraint
    }

    /// Pins the view to a fixed width.
    @discardableResult
    func width(_ value: CGFloat, priority: UILayoutPriority = .required) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let constraint = widthAnchor.constraint(equalToConstant: value)
        constraint.priority = priority
        constraint.isActive = true
        return constraint
    }

    /// Pins the view to a fixed width × height.
    @discardableResult
    func size(_ size: CGSize, priority: UILayoutPriority = .required) -> [NSLayoutConstraint] {
        [width(size.width, priority: priority), height(size.height, priority: priority)]
    }

    /// Pins this view's bottom to `other`'s top — i.e. stacks this view *above*
    /// `other` with optional `offset` (negative = overlap, positive = gap).
    @discardableResult
    func bottomToTop(of other: UIView, offset: CGFloat = 0) -> NSLayoutConstraint {
        translatesAutoresizingMaskIntoConstraints = false
        let constraint = bottomAnchor.constraint(equalTo: other.topAnchor, constant: offset)
        constraint.isActive = true
        return constraint
    }

    /// Sets the view's content-hugging priority for the given axis.
    /// Mirrors `TinyConstraints`' `setHugging(_:for:)` ergonomic; functionally
    /// identical to UIKit's built-in `setContentHuggingPriority(_:for:)`.
    func setHugging(_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) {
        setContentHuggingPriority(priority, for: axis)
    }

    /// Sets the view's content-compression-resistance priority for the given
    /// axis. Mirrors `TinyConstraints`' `setCompressionResistance(_:for:)`.
    func setCompressionResistance(_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) {
        setContentCompressionResistancePriority(priority, for: axis)
    }
}

// MARK: - Private

private extension UIView {
    /// Returns this view's superview or traps loudly. The "*ToSuperview" helpers
    /// are only meaningful once a parent exists; failing fast here is friendlier
    /// than a generic NSLayoutConstraint runtime crash later.
    func requireSuperview(file: StaticString = #file, line: UInt = #line) -> UIView {
        guard let superview else {
            fatalError(
                "\(type(of: self)) must be added to a superview before pinning constraints.",
                file: file,
                line: line
            )
        }
        return superview
    }
}
