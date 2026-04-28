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
import Factory
import SingleLineControllerCombine
import UIKit
import SingleLineControllerDIPrimitives
import SingleLineControllerController

/// Step 4 of Send — celebratory "transaction broadcast" screen with a stars
/// gradient background, copy/view-details buttons, and a skip CTA. Plays a
/// success sound + haptic when the receipt resolves.
final class PollTransactionStatusView: ScrollableStackViewOwner {
    /// Plays the success chime once the receipt resolves.
    @Injected(\.soundPlayer) private var soundPlayer: SoundPlayer
    /// Fires a celebratory haptic alongside the chime.
    @Injected(\.hapticFeedback) private var hapticFeedback: HapticFeedback

    /// Stars-gradient background.
    private lazy var motionEffectStarsImageViewWithGradient = GradientView()
    private lazy var checkmarkLogoImageView = UIImageView()
    private lazy var transactionBroadcastedLabel = UILabel()
    private lazy var mightTakeSomeMinutesLabel = UILabel()
    private lazy var copyTransactionIdButton = UIButton()
    private lazy var seeTxDetailsWhenAvailableButton = ButtonWithSpinner(mode: .nextToText)
    private lazy var skipWaitingOrDoneButton = UIButton()

    lazy var stackViewStyle = UIStackView.Style([
        checkmarkLogoImageView,
        .spacer,
        transactionBroadcastedLabel,
        mightTakeSomeMinutesLabel,
        copyTransactionIdButton,
        seeTxDetailsWhenAvailableButton,
        skipWaitingOrDoneButton,
    ], layoutMargins: UIEdgeInsets(top: 50, left: 16, bottom: 0, right: 16))

    override func setup() {
        setupSubviews()
    }
}

extension PollTransactionStatusView: ViewModelled {
    typealias ViewModel = PollTransactionStatusViewModel

    func populate(with viewModel: PollTransactionStatusViewModel.Output) -> [AnyCancellable] {
        let vibrateSuccessTrigger = viewModel.isSeeTxDetailsEnabled

        return [
            viewModel.skipWaitingOrDoneButtonTitle --> skipWaitingOrDoneButton.titleBinder(for: .normal),
            viewModel.isSeeTxDetailsEnabled --> seeTxDetailsWhenAvailableButton.isEnabledBinder,
            viewModel.isSeeTxDetailsButtonLoading --> seeTxDetailsWhenAvailableButton.isLoadingBinder,
            vibrateSuccessTrigger.sink { [weak self] finishedPolling in
                if !finishedPolling {
                    self?.playSound()
                }
                self?.vibrate()
            },
        ]
    }

    var inputFromView: InputFromView {
        InputFromView(
            copyTransactionIdTrigger: copyTransactionIdButton.tapPublisher,
            skipWaitingOrDoneTrigger: skipWaitingOrDoneButton.tapPublisher,
            seeTxDetails: seeTxDetailsWhenAvailableButton.tapPublisher
        )
    }
}

private extension PollTransactionStatusView {
    func setupSubviews() {
        checkmarkLogoImageView.withStyle(.default) {
            $0.image(UIImage(resource: .checkmarkLarge))
        }

        transactionBroadcastedLabel.withStyle(.header) {
            $0.text(String(localized: .PollTransaction.transactionBroadcasted)).textAlignment(.center)
        }

        mightTakeSomeMinutesLabel.withStyle(.body) {
            $0.text(String(localized: .PollTransaction.mightTakeSomeMinutes)).textAlignment(.center)
        }

        copyTransactionIdButton.withStyle(.secondary) {
            $0.title(String(localized: .PollTransaction.copyTransactionId))
        }

        seeTxDetailsWhenAvailableButton.withStyle(.primary) {
            $0.title(String(localized: .PollTransaction.seeTransactionDetails))
        }

        skipWaitingOrDoneButton.withStyle(.secondary)

        insertSubview(motionEffectStarsImageViewWithGradient, belowSubview: scrollView)
        motionEffectStarsImageViewWithGradient.edgesToSuperview()
        addStarsImagesWithMotionEffect(to: motionEffectStarsImageViewWithGradient)
    }

    func addStarsImagesWithMotionEffect(to view: UIView) {
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false

        let stars = UIImage(resource: .middleStars)
        let starsVerticallyFlipped = stars.withVerticallyFlippedOrientation(yOffset: -stars.size.height / 2)
        let starsHorizontallyFlipped = stars.withHorizontallyFlippedOrientation()

        view.addMotionEffectFromImages(
            front: stars,
            middle: starsVerticallyFlipped,
            back: starsHorizontallyFlipped
        )
    }

    func vibrate() {
        hapticFeedback.notify(.success)
    }

    /// Sound found here: https://freesound.org/people/MATTIX/sounds/445723/
    func playSound() {
        soundPlayer.play(resource: "freesound_mattix_radar", withExtension: "wav")
    }
}
