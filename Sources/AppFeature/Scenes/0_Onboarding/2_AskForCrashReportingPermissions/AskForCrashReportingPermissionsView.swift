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
import NanoViewControllerCombine
import NanoViewControllerController
import NanoViewControllerSceneViews
import TinyConstraints
import UIKit

/// Crash-reporting opt-in screen: hero image, disclaimer text, "I have read"
/// checkbox, and a horizontally-paired Decline/Accept button row.
public final class AskForCrashReportingPermissionsView: ScrollableStackViewOwner {
    /// Hero analytics illustration at the top.
    private lazy var imageView = UIImageView()
    /// Header label.
    private lazy var headerLabel = UILabel()
    /// Long-form disclaimer rendered in a non-editable text view.
    private lazy var disclaimerTextView = UITextView()
    /// "I have read the disclaimer" checkbox — must be checked to enable buttons.
    private lazy var hasReadDisclaimerCheckbox = CheckboxWithLabel()
    /// "No thanks" button.
    private lazy var declineButton = UIButton()
    /// "Send anonymous reports" button.
    private lazy var acceptButton = UIButton()
    /// Horizontal stack pairing decline + accept side by side.
    private lazy var buttonsStackView = UIStackView(arrangedSubviews: [declineButton, acceptButton])

    // MARK: - StackViewStyling

    /// Vertical layout: hero, header, disclaimer, checkbox, buttons.
    public lazy var stackViewStyle: UIStackView.Style = [
        imageView,
        headerLabel,
        disclaimerTextView,
        hasReadDisclaimerCheckbox,
        buttonsStackView,
    ]

    /// Override-hook from `ScrollableStackViewOwner` — wires styling.
    override public func setup() {
        setupSubviews()
    }
}

// MARK: - ViewModelled

extension AskForCrashReportingPermissionsView: ViewModelled {
    public typealias ViewModel = AskForCrashReportingPermissionsViewModel

    /// Routes the view model's `areButtonsEnabled` to *both* buttons — they share the same gate.
    public func populate(with viewModel: ViewModel.Output) -> [AnyCancellable] {
        [
            viewModel.areButtonsEnabled --> declineButton.isEnabledBinder,
            viewModel.areButtonsEnabled --> acceptButton.isEnabledBinder,
        ]
    }

    /// Surfaces the checkbox state and both button taps to the view-model.
    public var inputFromView: InputFromView {
        InputFromView(
            isHaveReadDisclaimerCheckboxChecked: hasReadDisclaimerCheckbox.isCheckedPublisher,
            acceptTrigger: acceptButton.tapPublisher,
            declineTrigger: declineButton.tapPublisher
        )
    }
}

private extension AskForCrashReportingPermissionsView {
    /// Styling pass — sets the hero, header, disclaimer text, the "I have read"
    /// checkbox copy, and the two buttons (initially disabled until the
    /// checkbox flips them via the view-model's `areButtonsEnabled` output).
    func setupSubviews() {
        imageView.withStyle(.default) {
            $0.image(UIImage(resource: .analyticsLarge))
        }

        headerLabel.withStyle(.header) {
            $0.text(String(localized: .AskForCrashReporting.title))
        }

        disclaimerTextView.withStyle(.nonEditable) {
            $0.text(String(localized: .AskForCrashReporting.disclaimer)).isSelectable(false)
        }

        hasReadDisclaimerCheckbox.withStyle(.init(alignment: .center)) {
            $0.text(String(localized: .AskForCrashReporting.readDisclaimer))
        }

        declineButton.withStyle(.primary) {
            $0.title(String(localized: .AskForCrashReporting.optOut))
                .disabled()
        }

        acceptButton.withStyle(.primary) {
            $0.title(String(localized: .AskForCrashReporting.optIn))
                .disabled()
        }

        buttonsStackView.withStyle(.horizontalFillingEqually)
    }
}
