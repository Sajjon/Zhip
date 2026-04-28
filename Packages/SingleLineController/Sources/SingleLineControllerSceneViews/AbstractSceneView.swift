// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import SingleLineControllerCombine
import SingleLineControllerCore
import UIKit

/// Common base for every scene's root `UIView`. Owns a vertically-scrolling
/// container (`scrollView`) and, for `PullToRefreshCapable` subclasses,
/// installs a `UIRefreshControl`.
///
/// Subclasses don't override the abstract setup directly — they implement the
/// `setup()` hook. The internal `setupAbstractSceneView()` method seats the
/// scroll view, then `defer`s a call to `setup()` so subclass code runs after
/// the scroll view is in place.
///
/// The `refreshControl` property is `open` so consumers (Zhip, …) can override
/// to substitute a themed `UIRefreshControl` subclass without touching this file.
open class AbstractSceneView: UIView, ScrollViewOwner {
    /// Pull-to-refresh control. Lazy because not every scene is
    /// `PullToRefreshCapable` — paying the construction cost only when needed.
    /// Override in subclasses to substitute a themed subclass of `UIRefreshControl`.
    open lazy var refreshControl: UIRefreshControl = .init()

    /// The owned scroll view. May be a plain `UIScrollView` or a
    /// `SingleCellTypeTableView` (for table-backed scenes).
    public let scrollView: UIScrollView

    /// Designated initialiser — receives the scroll view from the subclass
    /// (so `BaseTableViewOwner` can substitute its table view) and runs the
    /// shared setup chain.
    public init(scrollView: UIScrollView) {
        self.scrollView = scrollView
        super.init(frame: .zero)
        setupAbstractSceneView()
    }

    /// Override hook for subclasses that need non-edge-pinning constraints
    /// (e.g. a header that sits above the scroll view).
    open func setupScrollViewConstraints() {
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    /// Storyboard init — unsupported, traps to enforce programmatic-only use.
    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }

    // MARK: Overridable

    /// Override this method from your scene views, setting up its subviews.
    open func setup() { /* override me */ }
}

// MARK: - Private

private extension AbstractSceneView {
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
    /// and seats the refresh control on the scroll view.
    func setupRefreshControl() {
        scrollView.alwaysBounceVertical = true
        scrollView.refreshControl = refreshControl
    }
}

// MARK: - Publishers & Binders

public extension PullToRefreshCapable where Self: AbstractSceneView {
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

    /// Binder that updates the refresh control's title text. Wraps `title`
    /// in a plain `NSAttributedString` and assigns to `attributedTitle` so
    /// the package doesn't depend on app-specific UIRefreshControl subclasses.
    var pullToRefreshTitleBinder: Binder<String> {
        Binder<String>(self) {
            $0.refreshControl.attributedTitle = NSAttributedString(string: $1)
        }
    }

    /// Publisher that fires each time the user triggers pull-to-refresh
    /// (the `.valueChanged` event on `UIRefreshControl`).
    var pullToRefreshTriggerPublisher: AnyPublisher<Void, Never> {
        refreshControl.publisher(for: .valueChanged).eraseToAnyPublisher()
    }
}
