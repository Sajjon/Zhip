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

/// "Create new vs restore existing" wallet chooser. Mirrors `WelcomeView`'s
/// layout but with two buttons (primary/secondary) and a different parallax background.
final class ChooseWalletView: UIView {
    /// Container hosting the three-layer parallax planet illustration.
    private lazy var motionEffectPlanetsImageView = UIView()
    /// Hero headline label.
    private lazy var impressionLabel = UILabel()
    /// Body copy below the hero.
    private lazy var subtitleLabel = UILabel()
    /// Primary CTA — emit `.createNewWallet`.
    private lazy var createNewWalletButton = UIButton()
    /// Secondary CTA — emit `.restoreWallet`.
    private lazy var restoreWalletButton = UIButton()

    /// Bottom-aligned vertical stack with a spacer pushing content down.
    private lazy var stackView = UIStackView(arrangedSubviews: [
        .spacer,
        impressionLabel,
        subtitleLabel,
        createNewWalletButton,
        restoreWalletButton,
    ])

    /// Designated init — wires constraints + styling via `setup()`.
    init() {
        super.init(frame: .zero)
        setup()
    }

    /// Storyboards/xibs aren't used in this app.
    required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }
}

extension ChooseWalletView: ViewModelled {
    typealias ViewModel = ChooseWalletViewModel
    /// Surfaces both button taps so the view-model can route them to navigation steps.
    var inputFromView: InputFromView {
        InputFromView(
            createNewWalletTrigger: createNewWalletButton.tapPublisher,
            restoreWalletTrigger: restoreWalletButton.tapPublisher
        )
    }
}

private extension ChooseWalletView {
    /// Builds the layout — same vertical-stack-on-parallax recipe as Welcome.
    func setup() {
        stackView.withStyle(.default) {
            $0.spacing(0)
        }

        stackView.setCustomSpacing(16, after: impressionLabel)
        stackView.setCustomSpacing(40, after: subtitleLabel)
        addSubview(stackView)
        stackView.edgesToSuperview()

        insertSubview(motionEffectPlanetsImageView, belowSubview: stackView)
        motionEffectPlanetsImageView.edgesToSuperview()
        setupPlanetsImageWithMotionEffect()

        impressionLabel.withStyle(.impression) {
            $0.text(String(localized: .ChooseWallet.impression))
        }

        subtitleLabel.withStyle(.body) {
            $0.text(String(localized: .ChooseWallet.setUpWallet))
        }

        createNewWalletButton.withStyle(.primary) {
            $0.title(String(localized: .ChooseWallet.newWallet))
        }

        restoreWalletButton.withStyle(.secondary) {
            $0.title(String(localized: .ChooseWallet.restoreWalletButton))
        }
    }

    /// Wires the three-layer planet parallax (planets near, stars middle, abyss far).
    func setupPlanetsImageWithMotionEffect() {
        motionEffectPlanetsImageView.backgroundColor = .clear
        motionEffectPlanetsImageView.translatesAutoresizingMaskIntoConstraints = false

        motionEffectPlanetsImageView.addMotionEffectFromImages(
            front: UIImage(resource: .frontPlanets),
            middle: UIImage(resource: .middleStars),
            back: UIImage(resource: .backAbyss)
        )
    }
}

extension UIImage {
    /// Returns a vertically-flipped copy of the receiver. Used by parallax
    /// helpers that want to mirror an asset rather than ship two image files.
    /// Crashes (`incorrectImplementation`) if the underlying `cgImage` is
    /// missing or the bitmap context fails to produce an output image.
    func withVerticallyFlippedOrientation(yOffset: CGFloat = 0) -> UIImage {
        guard let cgImage else {
            incorrectImplementation("should be able to read cgImage")
        }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        let bitmap = UIGraphicsGetCurrentContext()!

        bitmap.translateBy(x: size.width / 2, y: size.height / 2)
        bitmap.scaleBy(x: 1.0, y: 1.0)

        bitmap.translateBy(x: -size.width / 2, y: -size.height / 2)
        bitmap.draw(cgImage, in: CGRect(x: 0, y: yOffset, width: size.width, height: size.height))

        let imageFromContext = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let image = imageFromContext else {
            incorrectImplementation("should be able to flip image")
        }
        return image
    }
}
