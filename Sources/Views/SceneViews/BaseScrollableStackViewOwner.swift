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

/// Idiomatic shape used by every "vertical stack inside a scroll view" scene:
/// `BaseScrollableStackViewOwner` plus `StackViewStyling` so the scene can
/// declare a `stackViewStyle` and get the rest for free.
typealias ScrollableStackViewOwner = BaseScrollableStackViewOwner & StackViewStyling

/// `AbstractSceneView` specialisation that owns a content view inside a
/// vertical scroll view. The content view is built lazily by asking the
/// subclass (which must conform to `ContentViewProvider`) — typically
/// resulting in a `UIStackView`.
class BaseScrollableStackViewOwner: AbstractSceneView, EmptyInitializable {
    // MARK: Initialization

    /// `EmptyInitializable` entry point — `SceneController` constructs the
    /// scene view via `init()`. We pass a fresh empty `UIScrollView` to the
    /// abstract base, then run the local setup chain to seat the content view.
    required init() {
        super.init(scrollView: UIScrollView(frame: .zero))
        setupBaseScrollableStackViewOwner()
    }

    /// Storyboard init — unsupported, traps to enforce programmatic-only use.
    required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }

    /// Lazy content view inside the scroll view. Built once via
    /// `makeScrollViewContentView()`.
    lazy var scrollViewContentView: UIView = makeScrollViewContentView()

    /// Builds the content view by asking the subclass (which must conform to
    /// `ContentViewProvider`). Crashes loudly if the conformance is missing —
    /// the type system doesn't enforce it because `BaseScrollableStackViewOwner`
    /// itself is not a `ContentViewProvider`, only its subclasses (via the
    /// `ScrollableStackViewOwner` typealias) are.
    func makeScrollViewContentView() -> UIView {
        guard let contentViewProvider = self as? ContentViewProvider else {
            incorrectImplementation("Self should be ContentViewProvider")
        }
        return contentViewProvider.makeContentView()
    }
}

// MARK: - Private

private extension BaseScrollableStackViewOwner {
    /// Due to classes and inheritance we cannot name this `setupSuviews`, since the subclasses cannot use that name.
    /// Pins the content view inside the scroll view:
    ///   - matches the scroll view's width (so horizontal scrolling is disabled),
    ///   - is at least as tall as the scroll view (so short content centres),
    ///   - hugs all four edges (`topToSafeArea: false` so content can extend
    ///     under the nav bar; `bottomToSafeArea` only when pull-to-refresh is
    ///     in play, so the spinner clears the home indicator).
    func setupBaseScrollableStackViewOwner() {
        scrollViewContentView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(scrollViewContentView)

        scrollViewContentView.widthToSuperview()
        scrollViewContentView.heightToSuperview(relation: .equalOrGreater, priority: .defaultHigh)
        scrollViewContentView.edgesToParent(topToSafeArea: false, bottomToSafeArea: self is PullToRefreshCapable)
    }
}

private extension UIView {
    /// Pins this view's edges to its `superview`, choosing safe-area or
    /// raw anchors per side. Crashes if no superview exists.
    func edgesToParent(topToSafeArea: Bool, bottomToSafeArea: Bool) {
        guard let superview else { incorrectImplementation("Should have `superview`") }
        edgesTo(view: superview, topToSafeArea: topToSafeArea, bottomToSafeArea: bottomToSafeArea)
    }

    /// Pin to a specific view's edges. Top/bottom can independently choose
    /// safe-area vs. raw anchors; left/right always use raw anchors.
    func edgesTo(view: UIView, topToSafeArea: Bool = true, bottomToSafeArea: Bool = true) {
        let topAnchor = topToSafeArea ? view.safeAreaLayoutGuide.topAnchor : view.topAnchor
        let bottomAnchor = bottomToSafeArea ? view.safeAreaLayoutGuide.bottomAnchor : view.bottomAnchor

        [
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.topAnchor.constraint(equalTo: topAnchor),
            self.bottomAnchor.constraint(equalTo: bottomAnchor),
        ].forEach { $0.isActive = true }
    }
}
