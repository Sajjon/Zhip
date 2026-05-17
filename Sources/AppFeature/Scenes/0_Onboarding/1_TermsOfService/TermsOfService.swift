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

import Foundation
import NanoViewControllerController
import NanoViewControllerCore

/// `NanoViewController` glue for the Terms of Service screen.
///
/// Used in two different presentation contexts: as a hidden-bar onboarding
/// step (the Terms scrolls under a custom hero) and as a translucent-bar
/// modal opened from Settings. Each context picks the navigation bar layout
/// at construction time — the layout is stored and surfaced via the
/// instance-level ``controllerConfig`` override (the static
/// ``ControllerConfigProviding`` hook cannot read instance state).
public final class TermsOfService: NanoViewController<TermsOfServiceView> {
    /// Per-presentation navigation bar layout (hidden during onboarding,
    /// translucent in the Settings modal).
    public let navigationBarLayout: NavigationBarLayout

    /// Designated init that lets the call site pick the bar layout explicitly.
    init(viewModel: ViewModel, navigationBarLayout: NavigationBarLayout) {
        self.navigationBarLayout = navigationBarLayout
        super.init(viewModel: viewModel)
    }

    /// Convenience init used by the onboarding flow — defaults to a hidden bar.
    public required init(viewModel: ViewModel) {
        navigationBarLayout = .hidden
        super.init(viewModel: viewModel)
    }

    /// Storyboards/xibs aren't used in this app.
    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }

    /// Instance-level chrome — reads the construction-time layout. Static
    /// `ControllerConfigProviding.config` can't see instance state, so this
    /// scene exposes its chrome via the overridable instance property instead.
    override public var controllerConfig: ControllerConfig {
        ControllerConfig(navigationBarLayout: navigationBarLayout)
    }
}
