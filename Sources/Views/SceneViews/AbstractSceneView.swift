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

import Combine
import SingleLineControllerCombine
import SingleLineControllerCore
import UIKit

/// Common base for every scene's root `UIView`. Owns a vertically-scrolling
/// container (`scrollView`) and, for `PullToRefreshCapable` subclasses,
/// installs the project's themed `RefreshControl`.
///
/// Subclasses don't override the abstract setup directly — they implement the
/// `setup()` hook. The `setupAbstractSceneView()` method below seats the
/// scroll view, then `defer`s a call to `setup()` so subclass code runs after
/// the scroll view is in place.
class AbstractSceneView: UIView, ScrollViewOwner {
    /// Themed pull-to-refresh control. Lazy because not every scene is
    /// `PullToRefreshCapable` — paying the construction cost only when needed.
    lazy var refreshControl = RefreshControl()

    /// The owned scroll view. May be a plain `UIScrollView` or a
    /// `SingleCellTypeTableView` (for table-backed scenes).
    let scrollView: UIScrollView

    /// Designated initialiser — receives the scroll view from the subclass
    /// (so `BaseTableViewOwner` can substitute its table view) and runs the
    /// shared setup chain.
    init(scrollView: UIScrollView) {
        self.scrollView = scrollView
        super.init(frame: .zero)
        setupAbstractSceneView()
    }

    /// Override hook for subclasses that need non-edge-pinning constraints
    /// (e.g. a header that sits above the scroll view).
    func setupScrollViewConstraints() {
        scrollView.edgesToSuperview()
    }

    /// Storyboard init — unsupported, traps to enforce programmatic-only use.
    required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }

    // MARK: Overridable

    /// Override this method from you scene views, setting up its subviews.
    func setup() { /* override me */ }
}

// MARK: - Private

private extension AbstractSceneView {
    /// Due to classes and inheritance we cannot name this `setupSuviews`, since the subclasses cannot use that name.
    /// Top-level setup chain — disable autoresizing-mask, seat the scroll view,
    /// then either install pull-to-refresh (if conformant) or disable
    /// content-inset adjustment so the scroll view sits flush. `defer { setup() }`
    /// ensures the subclass hook runs *after* the abstract scaffolding.
    func setupAbstractSceneView() {
        defer { setup() }

        translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(scrollView)
        setupScrollViewConstraints()

        if self is PullToRefreshCapable {
            scrollView.contentInsetAdjustmentBehavior = .always
            setupRefreshControl()
        } else {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
    }

    /// Enables vertical bounce (so users can pull even when content is short)
    /// and seats the themed refresh control on the scroll view.
    func setupRefreshControl() {
        scrollView.alwaysBounceVertical = true
        scrollView.refreshControl = refreshControl
    }
}

// MARK: - Publishers & Binders

extension PullToRefreshCapable where Self: AbstractSceneView {
    /// Binder that drives `beginRefreshing()` / `endRefreshing()` on the
    /// refresh control. Bind a `Bool` publisher (typically the ViewModel's
    /// `ActivityIndicator.asPublisher()`) to control the spinner state.
    var isRefreshingBinder: Binder<Bool> {
        Binder<Bool>(self) { view, refreshing in
            if refreshing {
                view.refreshControl.beginRefreshing()
            } else {
                view.refreshControl.endRefreshing()
            }
        }
    }

    /// Binder that updates the refresh control's title text. Lets the
    /// ViewModel react to refresh state changes ("Pulling…" → "Refreshing…").
    var pullToRefreshTitleBinder: Binder<String> {
        Binder<String>(self) {
            $0.refreshControl.setTitle($1)
        }
    }

    /// Publisher that fires each time the user triggers pull-to-refresh
    /// (the `.valueChanged` event on `UIRefreshControl`).
    var pullToRefreshTriggerPublisher: AnyPublisher<Void, Never> {
        refreshControl.publisher(for: .valueChanged).eraseToAnyPublisher()
    }
}
