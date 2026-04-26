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

/// `UIButton` subclass that overlays a spinner during async work, surfaced to
/// the reactive layer via `isLoadingBinder`. Used as the primary continue button
/// across onboarding/restore/send flows.
final class ButtonWithSpinner: UIButton {
    /// Where the spinner sits relative to the button's text.
    enum SpinnerMode {
        /// Hide the title and centre the spinner — used on full-width primary
        /// buttons where the spinner is the only feedback during work.
        case replaceText
        /// Keep the title visible and put the spinner on the leading edge —
        /// used on inline buttons where the user needs the label context.
        case nextToText
    }

    /// The overlay spinner. Lazy because not every button is animated, and
    /// we shouldn't pay layer setup costs upfront.
    private lazy var spinnerView = SpinnerView()
    /// Chosen spinner placement. Stored so `start`/`stopSpinning` can branch.
    private let mode: SpinnerMode
    /// Designated initialiser. `mode` defaults to `.replaceText` since that's
    /// the most common use across the app.
    init(mode: SpinnerMode = .replaceText) {
        self.mode = mode
        super.init(frame: .zero)
        setup()
    }

    /// Storyboard init — unsupported, traps to enforce programmatic-only use.
    required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }
}

extension ButtonWithSpinner {
    /// Begin the spinner. In `.replaceText` mode also zeroes the title's
    /// opacity (rather than removing it, so the button keeps its sized layout).
    func startSpinning() {
        switch mode {
        case .replaceText:
            titleLabel?.layer.opacity = 0
            bringSubviewToFront(spinnerView)
        case .nextToText: break
        }

        spinnerView.startSpinning()
    }

    /// Stop the spinner and restore the title. `.replaceText` mode pushes the
    /// (now-hidden) spinner back below the title for cleanliness.
    func stopSpinning() {
        switch mode {
        case .replaceText:
            titleLabel?.layer.opacity = 1
            sendSubviewToBack(spinnerView)
        case .nextToText: break
        }
        spinnerView.stopSpinning()
    }
}

private extension ButtonWithSpinner {
    /// Seats the spinner inside the button. `.replaceText` centres it (with a
    /// small vertical inset so the rotation isn't clipped); `.nextToText`
    /// pins it to the leading edge at a fixed 32×32.
    func setup() {
        addSubview(spinnerView)
        switch mode {
        case .replaceText:
            spinnerView.edgesToSuperview(insets: UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0))
        case .nextToText:
            spinnerView.size(CGSize(width: 32, height: 32))
            spinnerView.leftToSuperview(offset: 20)
            spinnerView.centerYToSuperview()
        }
    }

    /// Bool→start/stop bridge used by `isLoadingBinder`.
    func changeTo(isSpinning: Bool) {
        if isSpinning {
            startSpinning()
        } else {
            stopSpinning()
        }
    }
}

extension ButtonWithSpinner {
    /// Reactive sink: bind a `Bool` publisher (typically the ViewModel's
    /// `ActivityIndicator.asPublisher()`) to drive the spinner.
    var isLoadingBinder: Binder<Bool> {
        Binder(self) {
            $0.changeTo(isSpinning: $1)
        }
    }
}
