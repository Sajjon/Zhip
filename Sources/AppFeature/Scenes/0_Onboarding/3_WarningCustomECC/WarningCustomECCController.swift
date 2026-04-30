//
//  WarningCustomECCController.swift
//  Zhip
//
//  Created by Alexander Cyon on 2019-02-08.
// Copyright (c) 2018-2026 Open Zesame (https://github.com/OpenZesame)
//

import SingleLineControllerCore
import UIKit
import SingleLineControllerController

/// `SceneController` glue for the "we use a custom ECC implementation" warning screen.
///
/// Same dual-presentation pattern as Terms / CrashReporting: hidden bar in onboarding,
/// translucent bar with a "Done" button when re-opened from Settings.
public final class WarningCustomECC: Scene<WarningCustomECCView>, NavigationBarLayoutOwner {
    /// Per-presentation navigation-bar layout.
    public let navigationBarLayout: NavigationBarLayout

    /// Designated init that lets the call site pick the bar layout explicitly.
    init(viewModel: ViewModel, navigationBarLayout: NavigationBarLayout) {
        self.navigationBarLayout = navigationBarLayout
        super.init(viewModel: viewModel)
    }

    /// Convenience init used by the onboarding flow — defaults to a hidden bar.
    required init(viewModel: ViewModel) {
        navigationBarLayout = .hidden
        super.init(viewModel: viewModel)
    }

    /// Storyboards/xibs aren't used in this app.
    required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }
}
