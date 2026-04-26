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

/// Privacy-cover screen shown over the live Main UI when the app goes to the
/// background. Renders the app name on a parallax aurora background.
///
/// Used by `AppCoordinator` to mask the wallet contents from the iOS app
/// switcher snapshot — the snapshot would otherwise expose the user's balance
/// and address in the multitasking carousel.
///
/// Doesn't subclass `Scene<View>` because it has no view-model — purely static.
final class LockAppScene: AbstractController {
    /// Container hosting the three-layer parallax aurora illustration.
    private lazy var motionEffectAuroraImageView = UIView()
    /// Centered app-name label drawn over the aurora.
    private lazy var titleLabel = UILabel()
    /// Builds the static layout — black background, parallax aurora behind a
    /// centered app-name label drawn in the "bigBang" hero font.
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(motionEffectAuroraImageView)
        motionEffectAuroraImageView.addSubview(titleLabel)
        motionEffectAuroraImageView.edgesToSuperview()
        titleLabel.centerInSuperview()

        let appName = Bundle.main.name ?? "Zhip"

        titleLabel.withStyle(.impression) {
            $0.font(.bigBang).text(appName).textColor(.white)
        }

        addAuroraImagesWithMotionEffect(to: motionEffectAuroraImageView)
        motionEffectAuroraImageView.bringSubviewToFront(titleLabel)
    }
}
