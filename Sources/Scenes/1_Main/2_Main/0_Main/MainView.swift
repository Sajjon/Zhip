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

import Combine
import UIKit

/// Wallet hub screen — shows balance with pull-to-refresh + send/receive CTAs.
/// `PullToRefreshCapable` brings in the refresh control + its publishers.
final class MainView: ScrollableStackViewOwner, PullToRefreshCapable {
    /// Container hosting the parallax aurora background.
    private lazy var motionEffectAuroraImageView = UIView()
    /// "Balance" label above the value.
    private lazy var balanceTitleLabel = UILabel()
    /// The big balance number — uses the impression font.
    private lazy var balanceValueLabel = UILabel()
    /// Zilliqa logo aligned bottom-left of the balance number.
    private lazy var zilliqaBalanceImageView = UIImageView()
    private lazy var zilliqaImageVerticalPositioner = UIStackView(arrangedSubviews: [
        .spacer,
        zilliqaBalanceImageView,
        .spacer(height: 10),
    ])
    private lazy var balanceValueAndIconStackView = UIStackView(arrangedSubviews: [
        balanceValueLabel,
        zilliqaImageVerticalPositioner,
        .spacer,
    ])
    private lazy var balanceViews = UIStackView(arrangedSubviews: [balanceTitleLabel, balanceValueAndIconStackView])
    private lazy var sendButton = ImageAboveLabelButton()
    private lazy var receiveButton = ImageAboveLabelButton()
    private lazy var buttonsView = UIStackView(arrangedSubviews: [sendButton, receiveButton])

    lazy var stackViewStyle = UIStackView.Style([
        balanceViews,
        .spacer,
        buttonsView,
    ], spacing: 8)

    override func setup() {
        setupSubviews()
    }
}

extension MainView: ViewModelled {
    typealias ViewModel = MainViewModel

    /// Surfaces pull-to-refresh + the two CTA taps.
    var inputFromView: InputFromView {
        InputFromView(
            pullToRefreshTrigger: pullToRefreshTriggerPublisher,
            sendTrigger: sendButton.tapPublisher,
            receiveTrigger: receiveButton.tapPublisher
        )
    }

    /// Binds fetching state → refresh-spinner, balance string → big number,
    /// and last-updated copy → the refresh control's title.
    func populate(with viewModel: MainViewModel.Output) -> [AnyCancellable] {
        [
            viewModel.isFetchingBalance --> isRefreshingBinder,
            viewModel.balance --> balanceValueLabel.textBinder,
            viewModel.refreshControlLastUpdatedTitle --> pullToRefreshTitleBinder,
        ]
    }
}

private extension MainView {
    /// Styling pass — labels, logo image, two image-above-label buttons,
    /// and the parallax aurora background inserted *behind* the scrollView
    /// so it stays put while content scrolls.
    func setupSubviews() {
        balanceTitleLabel.withStyle(.init(
            text: String(localized: .Main.balanceTitle),
            textColor: UIColor.white.withAlphaComponent(0.7),
            font: .callToAction
        ))

        balanceValueLabel.withStyle(.impression) {
            $0.font(.bigBang).minimumScaleFactor(0.5)
        }

        let zilliqaLogo = UIImage(resource: .zilliqaLogo).withRenderingMode(.alwaysOriginal)
        zilliqaBalanceImageView.withStyle(.init(image: zilliqaLogo, contentMode: UIView.ContentMode.bottomLeft))

        zilliqaImageVerticalPositioner.withStyle(.vertical) {
            $0.spacing(0)
        }

        balanceValueAndIconStackView.withStyle(.horizontal) {
            $0.spacing(4)
        }
        balanceViews.withStyle(.default) {
            $0.spacing(0)
        }

        sendButton.setTitle(String(localized: .Main.send), image: UIImage(resource: .send))
        receiveButton.setTitle(String(localized: .Main.receive), image: UIImage(resource: .receive))

        buttonsView.withStyle(.horizontal) {
            $0.distribution(.fillEqually)
        }

        buttonsView.height(184)

        insertSubview(motionEffectAuroraImageView, belowSubview: scrollView)
        motionEffectAuroraImageView.edgesToSuperview()
        addAuroraImagesWithMotionEffect(to: motionEffectAuroraImageView)
    }
}

/// Shared helper that wires the three-layer aurora parallax into `effectView`.
/// Used by both `MainView` and `LockAppScene` so the visual effect is identical.
func addAuroraImagesWithMotionEffect(to effectView: UIView) {
    effectView.backgroundColor = .clear
    effectView.translatesAutoresizingMaskIntoConstraints = false

    effectView.addMotionEffect(
        front: UIImage(resource: .frontAurora),
        middle: UIImage(resource: .middleAurora),
        back: UIImage(resource: .backAurora)
    )
}
