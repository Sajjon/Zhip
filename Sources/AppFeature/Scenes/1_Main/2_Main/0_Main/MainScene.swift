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
import UIKit

/// `NanoViewController` glue for the wallet hub screen.
///
/// * Right-bar settings cog icon — taps fire `goToSettings` on the view-model.
/// * Translucent navigation bar so the parallax aurora background bleeds
///   under it.
///
/// The translucent bar layout reads brand defaults that are `@MainActor`-
/// isolated, so the config is computed via an `@MainActor` accessor instead
/// of a stored `static let` (the initialiser expression would otherwise be
/// evaluated off-main during static-let lazy init).
public final class Main: NanoViewController<MainView>, ControllerConfigProviding {
    @MainActor
    public static var config: ControllerConfig {
        ControllerConfig(
            rightBarButton: BarButtonContent(image: UIImage(resource: .settings)),
            navigationBarLayout: .translucent
        )
    }
}
