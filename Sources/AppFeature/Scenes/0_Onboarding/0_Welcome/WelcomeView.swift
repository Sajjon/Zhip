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

import SingleLineControllerCombine
import SingleLineControllerCore
import UIKit
import SingleLineControllerController

/// First-run welcome screen: a parallax spaceship illustration with a
/// "Get Started" CTA. The view owns the layout, the view model just bridges
/// the button tap to the onboarding coordinator.
public final class WelcomeView: UIView {
    /// Container hosting the three-layer parallax spaceship illustration.
    private lazy var motionEffectSpaceshipImageView = UIView()
    /// Hero headline label ("Welcome").
    private lazy var impressionLabel = UILabel()
    /// Body copy below the hero.
    private lazy var subtitleLabel = UILabel()
    /// Primary CTA — its tap is the only user input on this screen.
    private lazy var startButton = UIButton()

    /// Bottom-aligned vertical stack with a spacer pushing the content down.
    private lazy var stackView = UIStackView(arrangedSubviews: [
        .spacer,
        impressionLabel,
        subtitleLabel,
        startButton,
    ])

    /// Designated init — wires constraints + styling via `setup()`.
    public init() {
        super.init(frame: .zero)
        setup()
    }

    /// Storyboards/xibs aren't used in this app.
    required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }
}

extension WelcomeView: ViewModelled {
    public typealias ViewModel = WelcomeViewModel

    /// Single-input bridge: the start button's tap publisher.
    public var inputFromView: InputFromView {
        InputFromView(
            startTrigger: startButton.tapPublisher
        )
    }
}

// MARK: - Private

private extension WelcomeView {
    /// Builds the layout: the spaceship motion-effect view sits behind a
    /// vertical stack of (spacer, hero, body, CTA). Custom spacings tighten
    /// the hero/body cluster and gap the body away from the button.
    func setup() {
        stackView.withStyle(.default) {
            $0.spacing(0)
        }

        stackView.setCustomSpacing(16, after: impressionLabel)
        stackView.setCustomSpacing(40, after: subtitleLabel)
        addSubview(stackView)
        stackView.edgesToSuperview()

        // Background spaceship sits behind the text stack so the motion
        // parallax is visible through the (transparent) stackView.
        insertSubview(motionEffectSpaceshipImageView, belowSubview: stackView)
        motionEffectSpaceshipImageView.edgesToSuperview()
        setupSpaceshipImageWithMotionEffect()

        impressionLabel.withStyle(.impression) {
            $0.text(String(localized: .Welcome.header))
        }

        subtitleLabel.withStyle(.body) {
            $0.text(String(localized: .Welcome.body))
        }

        startButton.withStyle(.primary) {
            $0.title(String(localized: .Welcome.start))
        }
    }

    /// Wires the three-layer parallax (clouds far, spaceship middle, blast-off near)
    /// driven by device motion via `UIInterpolatingMotionEffect`.
    func setupSpaceshipImageWithMotionEffect() {
        motionEffectSpaceshipImageView.backgroundColor = .clear
        motionEffectSpaceshipImageView.translatesAutoresizingMaskIntoConstraints = false

        motionEffectSpaceshipImageView.addMotionEffect(
            front: UIImage(resource: .frontBlastOff),
            middle: UIImage(resource: .middleSpaceship),
            back: UIImage(resource: .backClouds)
        )
    }
}
