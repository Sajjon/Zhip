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

@testable import AppFeature
import UIKit
import XCTest

/// View-hierarchy traversal helpers used by Coordinator tests to drive
/// user actions through the actual UIKit controls — since the stored
/// `viewModel.navigator` shim was removed, tests can no longer poke the
/// navigator directly. Instead they walk the production view tree, find
/// the relevant `UIControl` (or `UIView` subclass), and fire
/// `sendActions(for:)` to simulate a real tap.
extension UIView {
    /// Depth-first search of the view hierarchy for the first subview
    /// satisfying `predicate`. Useful when production views keep their
    /// subviews `private` — tests can locate them by type or by
    /// accessibility identifier.
    ///
    /// For `UIStackView`s the traversal walks `arrangedSubviews` rather
    /// than `subviews`, because the order in `subviews` reflects the
    /// raw `addSubview` insertion order (which our app's
    /// `apply(style:)` reverses via `views.reversed().forEach { insertArrangedSubview($0, at: 0) }`).
    /// `arrangedSubviews` reliably matches the visual top-to-bottom order.
    ///
    /// - Parameter predicate: returns `true` for the subview to return.
    /// - Returns: the first match anywhere in the subtree, or `nil`.
    func firstSubview(where predicate: (UIView) -> Bool) -> UIView? {
        for subview in orderedSubviewsForTraversal {
            if predicate(subview) { return subview }
            if let match = subview.firstSubview(where: predicate) { return match }
        }
        return nil
    }

    /// All subviews (depth-first, recursive) satisfying `predicate`.
    /// Used when a view contains several buttons of the same type and
    /// the test needs the *n*-th one (e.g. `MainView` has two
    /// `ImageAboveLabelButton`s — index 0 = send, index 1 = receive).
    ///
    /// Uses ``orderedSubviewsForTraversal`` (which honours
    /// `UIStackView.arrangedSubviews` order) so the index callers pass
    /// matches the visual top-to-bottom order of the production view.
    func allSubviews(where predicate: (UIView) -> Bool) -> [UIView] {
        var result: [UIView] = []
        for subview in orderedSubviewsForTraversal {
            if predicate(subview) { result.append(subview) }
            result.append(contentsOf: subview.allSubviews(where: predicate))
        }
        return result
    }

    /// `UIStackView.arrangedSubviews` for stack views (visual top-to-bottom
    /// order), falling back to `subviews` otherwise. Internal seam used by
    /// the traversal helpers above so callers don't have to think about
    /// it. Plain `UIView` subviews are unaffected.
    fileprivate var orderedSubviewsForTraversal: [UIView] {
        if let stack = self as? UIStackView {
            // Include any non-arranged subviews after the arranged ones so
            // hand-added children (rare, but possible) aren't lost.
            let arranged = stack.arrangedSubviews
            let extras = stack.subviews.filter { !arranged.contains($0) }
            return arranged + extras
        }
        return subviews
    }

    /// Convenience: every `UIControl` in the subtree, optionally filtered
    /// by a typed predicate. Saves callers writing `.compactMap { $0 as? UIControl }`.
    func allControls(where predicate: (UIControl) -> Bool = { _ in true }) -> [UIControl] {
        allSubviews(where: { ($0 as? UIControl).map(predicate) ?? false })
            .compactMap { $0 as? UIControl }
    }

    /// Convenience: first subview of a specific subclass, optionally
    /// constrained by `predicate`.
    func firstSubview<T: UIView>(ofType _: T.Type, where predicate: (T) -> Bool = { _ in true }) -> T? {
        firstSubview { ($0 as? T).map(predicate) ?? false } as? T
    }

    /// Convenience: every subview of a specific subclass.
    func allSubviews<T: UIView>(ofType _: T.Type) -> [T] {
        allSubviews(where: { $0 is T }).compactMap { $0 as? T }
    }
}

extension Array {
    /// Bounds-checking subscript: returns `nil` rather than crashing when
    /// `index` is out of range. Useful in tests that look up a button by
    /// depth-first index — a clear `nil` returned from `XCTUnwrap` produces
    /// a much more readable failure than an index-out-of-range trap.
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

/// Fires `.touchUpInside` on the `UIButton` at the given depth-first index
/// within `view`'s subtree.
///
/// Replaces the old `viewModel.navigator.next(.X)` shortcut after the stored
/// navigator was removed from ViewModels. Walks the production view tree,
/// finds the *n*-th `UIButton`, and triggers it, so the test exercises the
/// real `tapPublisher → viewModel → coordinator` pipeline.
@MainActor
func tapButton(at index: Int, in view: UIView, file: StaticString = #file, line: UInt = #line) throws {
    // Force layout so lazy subviews are present.
    view.setNeedsLayout()
    view.layoutIfNeeded()
    let buttons = view.allSubviews(ofType: UIButton.self)
    let button = try XCTUnwrap(
        buttons[safe: index],
        "Expected UIButton at index \(index), found \(buttons.count) buttons (types: \(buttons.map { String(describing: type(of: $0)) }))",
        file: file,
        line: line
    )
    // `sendActions(for:)` walks the target/action map; in unit tests it occasionally
    // no-ops if the control hasn't been touched by the responder chain yet. Walk
    // the targets explicitly and invoke each registered selector with the control
    // and event sentinel — equivalent to a real `.touchUpInside`.
    if let targets = button.allTargets as Set<AnyHashable>? as? Set<AnyHashable>, !targets.isEmpty {
        for target in button.allTargets {
            if let actions = button.actions(forTarget: target, forControlEvent: .touchUpInside) {
                for action in actions {
                    let selector = Selector(action)
                    _ = (target as AnyObject).perform(selector, with: button)
                }
            }
        }
    } else {
        button.sendActions(for: .touchUpInside)
    }
}

/// Fires `.touchUpInside` on the first `UIControl` of a specific subclass
/// (e.g. `ImageAboveLabelButton`) at `index` within `view`'s subtree.
@MainActor
func tapControl<T: UIControl>(
    _: T.Type,
    at index: Int = 0,
    in view: UIView,
    file: StaticString = #file,
    line: UInt = #line
) throws {
    view.layoutIfNeeded()
    let controls = view.allSubviews(ofType: T.self)
    let control = try XCTUnwrap(
        controls[safe: index],
        "Expected \(T.self) at index \(index), found \(controls.count)",
        file: file,
        line: line
    )
    control.sendActions(for: .touchUpInside)
}

/// Sets a `CheckboxView`'s `on` state and fires `.valueChanged` so any
/// Combine subscribers observing `isCheckedPublisher` receive the new
/// value. Real user touches go through `beginTracking`; tests can't
/// drive that synchronously, so we shortcut the public setter +
/// action-firing combo here.
@MainActor
func setCheckbox(
    on isOn: Bool,
    in view: UIView,
    at index: Int = 0,
    file: StaticString = #file,
    line: UInt = #line
) throws {
    view.layoutIfNeeded()
    let checkboxes = view.allSubviews(ofType: CheckboxView.self)
    let checkbox = try XCTUnwrap(
        checkboxes[safe: index],
        "Expected CheckboxView at index \(index), found \(checkboxes.count)",
        file: file,
        line: line
    )
    checkbox.setOn(isOn, animated: false)
    checkbox.sendActions(for: .valueChanged)
}

/// Drives a pincode entry into the first `InputPincodeView` found in
/// `view`'s subtree. We assign the underlying text field's `.text` and
/// post `UITextField.textDidChangeNotification` so the internal
/// `textPublisher` (which merges `Just(text)` with the notification
/// stream) re-emits and the field's `pincodeSubject` fires with the
/// parsed pincode.
@MainActor
func enterPincode(
    _ pincode: Pincode,
    in view: UIView,
    file: StaticString = #file,
    line: UInt = #line
) throws {
    view.layoutIfNeeded()
    let pincodeViews = view.allSubviews(ofType: InputPincodeView.self)
    let pincodeView = try XCTUnwrap(
        pincodeViews.first,
        "Expected an InputPincodeView in the subtree",
        file: file,
        line: line
    )
    let pinField = pincodeView.pinField
    pinField.text = pincode.digits.map { String($0.rawValue) }.joined()
    NotificationCenter.default.post(name: UITextField.textDidChangeNotification, object: pinField)
}

/// Sets the `text` of a `UITextField` at the given depth-first index
/// and posts `UITextField.textDidChangeNotification` so any reactive
/// subscribers (e.g. `textPublisher`) re-emit. Tests use this to feed
/// password fields or address entries that gate a CTA button.
@MainActor
func setText<T: UITextField>(
    _ text: String,
    in view: UIView,
    ofType type: T.Type = UITextField.self,
    at index: Int = 0,
    file: StaticString = #file,
    line: UInt = #line
) throws {
    view.layoutIfNeeded()
    let fields = view.allSubviews(ofType: type)
    let field = try XCTUnwrap(
        fields[safe: index],
        "Expected \(type) at index \(index), found \(fields.count)",
        file: file,
        line: line
    )
    field.text = text
    NotificationCenter.default.post(name: UITextField.textDidChangeNotification, object: field)
}

/// Selects a row in the first `UITableView` found in `view`'s subtree.
/// Calls the delegate's `tableView(_:didSelectRowAt:)` directly — that's
/// the path the `SingleCellTypeTableView` uses to push into its
/// `selectionPublisher`, so the reactive chain fires exactly as it would
/// for a real tap.
@MainActor
func selectTableRow(
    section: Int,
    row: Int,
    in view: UIView,
    file: StaticString = #file,
    line: UInt = #line
) throws {
    view.layoutIfNeeded()
    let tableViews = view.allSubviews(ofType: UITableView.self)
    let tableView = try XCTUnwrap(
        tableViews.first,
        "Expected a UITableView in the subtree",
        file: file,
        line: line
    )
    let indexPath = IndexPath(row: row, section: section)
    // Ensure the view-model has emitted sections first by laying out (the
    // diffable data source applies a snapshot on the runloop). Tests that
    // need the data populated should call `drainRunLoop()` before invoking
    // this helper.
    tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
}
