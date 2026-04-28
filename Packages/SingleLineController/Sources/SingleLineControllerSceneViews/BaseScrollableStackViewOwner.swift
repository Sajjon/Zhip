// MIT License — Copyright (c) 2018-2026 Open Zesame

import SingleLineControllerCore
import UIKit

/// `AbstractSceneView` specialisation that owns a content view inside a
/// vertical scroll view. The content view is built lazily by asking the
/// subclass (which must conform to `ContentViewProvider`) — typically
/// resulting in a `UIStackView`.
///
/// Conforms to `EmptyInitializable` so `SceneController` can construct it
/// from the `View` generic constraint without consumers having to write a
/// custom factory.
open class BaseScrollableStackViewOwner: AbstractSceneView, EmptyInitializable {
    // MARK: Initialization

    /// `EmptyInitializable` entry point — `SceneController` constructs the
    /// scene view via `init()`. Passes a fresh empty `UIScrollView` to the
    /// abstract base, then runs the local setup chain to seat the content view.
    public required init() {
        super.init(scrollView: UIScrollView(frame: .zero))
        setupBaseScrollableStackViewOwner()
    }

    /// Storyboard init — unsupported, traps to enforce programmatic-only use.
    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }

    /// Lazy content view inside the scroll view. Built once via
    /// `makeScrollViewContentView()`.
    public lazy var scrollViewContentView: UIView = makeScrollViewContentView()

    /// Builds the content view by asking the subclass (which must conform to
    /// `ContentViewProvider`). Crashes loudly if the conformance is missing —
    /// the type system doesn't enforce it because `BaseScrollableStackViewOwner`
    /// itself is not a `ContentViewProvider`, only its subclasses are.
    open func makeScrollViewContentView() -> UIView {
        guard let contentViewProvider = self as? ContentViewProvider else {
            incorrectImplementation("Self should be ContentViewProvider")
        }
        return contentViewProvider.makeContentView()
    }
}

// MARK: - Private

private extension BaseScrollableStackViewOwner {
    /// Pins the content view inside the scroll view:
    ///   - matches the scroll view's width (so horizontal scrolling is disabled),
    ///   - is at least as tall as the scroll view (so short content centres),
    ///   - hugs all four edges (`topToSafeArea: false` so content can extend
    ///     under the nav bar; `bottomToSafeArea` only when pull-to-refresh is
    ///     in play, so the spinner clears the home indicator).
    func setupBaseScrollableStackViewOwner() {
        scrollViewContentView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(scrollViewContentView)

        let contentLayoutGuide = scrollView.contentLayoutGuide
        let frameLayoutGuide = scrollView.frameLayoutGuide
        let bottomToSafeArea = self is PullToRefreshCapable
        let bottomAnchor = bottomToSafeArea ? safeAreaLayoutGuide.bottomAnchor : self.bottomAnchor

        let heightAtLeastFrame = scrollViewContentView.heightAnchor.constraint(
            greaterThanOrEqualTo: frameLayoutGuide.heightAnchor
        )
        heightAtLeastFrame.priority = .defaultHigh

        NSLayoutConstraint.activate([
            scrollViewContentView.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor),
            heightAtLeastFrame,
            scrollViewContentView.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
            scrollViewContentView.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
            scrollViewContentView.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
            scrollViewContentView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
