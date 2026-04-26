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

/// Custom pull-to-refresh control that replaces UIKit's bundled spinner with
/// the project's themed `SpinnerView` plus a centred title label, so the
/// pull-to-refresh styling matches the rest of the app's chrome.
final class RefreshControl: UIRefreshControl {
    /// Themed spinner shown above the label. Always spinning while visible.
    private lazy var spinner = SpinnerView()
    /// Label below the spinner — content driven via `setTitle(_:)`.
    private lazy var label = UILabel()
    /// Vertical stack composing spinner + label.
    private lazy var stackView = UIStackView(arrangedSubviews: [spinner, label])

    /// Programmatic initialiser. Spins up the layout via `setup()`.
    override init() {
        super.init(frame: .zero)
        setup()
    }

    /// Storyboard init — unsupported, traps to enforce programmatic-only use.
    required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }

    /// Workaround that hides UIKit's built-in default spinner. Setting
    /// `isHidden = true` doesn't work on the private subview, but zeroing
    /// `alpha` does. Without this hack the system spinner shows through
    /// alongside our custom `SpinnerView`, which looks broken.
    /// Original technique: https://stackoverflow.com/a/33472020/1311272
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil else { return }
        // setting `isHidden = true` does not work
        subviews.first?.alpha = 0
    }
}

extension RefreshControl {
    /// Updates the visible label text under the spinner. Called reactively from
    /// scenes that want to swap the prompt mid-refresh (e.g. "pulling…" → "refreshing…").
    func setTitle(_ title: String) {
        label.text = title
    }
}

private extension RefreshControl {
    /// Lays out the spinner+label stack, applies project styling, and starts
    /// the spinner immediately so it is animating the moment the user pulls.
    func setup() {
        backgroundColor = .clear
        contentMode = .scaleToFill
        autoresizingMask = [.flexibleWidth, .flexibleHeight]

        label.withStyle(.init(textAlignment: .center, textColor: .white, font: .title))
        stackView.withStyle(.vertical) {
            $0.distribution(.fill).spacing(0)
        }
        addSubview(stackView)
        spinner.height(30, priority: .defaultHigh)
        stackView.edgesToSuperview()
        spinner.startSpinning()
        setTitle(String(localized: .Views.pullToRefreshTitle))
    }
}
