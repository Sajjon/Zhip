//
//  WarningCustomECCView.swift
//  Zhip
//
//  Created by Alexander Cyon on 2019-02-08.
// Copyright (c) 2018-2026 Open Zesame (https://github.com/OpenZesame)
//

import Combine
import Factory
import SingleLineControllerCombine
import UIKit
import SingleLineControllerController

/// Custom-ECC warning screen — identical layout to Terms but with a warning
/// triangle hero and selectable text (so the linked bug-bounty URL is tappable).
final class WarningCustomECCView: ScrollableStackViewOwner {
    /// Hero warning illustration.
    private lazy var imageView = UIImageView()
    /// "Custom ECC implementation" header.
    private lazy var headerLabel = UILabel()
    /// HTML-rendered warning text. Selectable so embedded `<a href>` links work.
    private lazy var textView = UITextView()
    /// Bottom CTA — disabled until the user has scrolled near the bottom.
    private lazy var acceptTermsButton = UIButton()

    // MARK: - StackViewStyling

    /// Vertical layout: hero, header, text, CTA.
    lazy var stackViewStyle: UIStackView.Style = [
        imageView,
        headerLabel,
        textView,
        acceptTermsButton,
    ]

    /// Override-hook from `ScrollableStackViewOwner` — wires styling.
    override func setup() {
        setupSubviews()
    }
}

extension WarningCustomECCView: ViewModelled {
    typealias ViewModel = WarningCustomECCViewModel

    /// Binds visibility (hidden in dismissible variant) and enabled state.
    func populate(with viewModel: ViewModel.Output) -> [AnyCancellable] {
        [
            viewModel.isAcceptButtonVisible --> acceptTermsButton.isVisibleBinder,
            viewModel.isAcceptButtonEnabled --> acceptTermsButton.isEnabledBinder,
        ]
    }

    /// Surfaces "scrolled to bottom" + "accepted" to the view-model.
    var inputFromView: InputFromView {
        InputFromView(
            didScrollToBottom: textView.didScrollNearBottomPublisher(),
            didAcceptTerms: acceptTermsButton.tapPublisher
        )
    }
}

private extension WarningCustomECCView {
    /// Styling pass — sets the warning hero, header, accept button (disabled
    /// initially), and loads the warning HTML through the injected `HtmlLoader`.
    /// Re-enables `isSelectable` after `withStyle(.nonSelectable)` so the
    /// embedded bug-bounty hyperlink becomes tappable.
    func setupSubviews() {
        imageView.withStyle(.default) {
            $0.image(UIImage(resource: .warningLarge))
        }

        headerLabel.withStyle(.header) {
            $0.text(String(localized: .WarningCustomECC.header))
        }

        acceptTermsButton.withStyle(.primary) {
            $0.title(String(localized: .WarningCustomECC.accept))
                .disabled()
        }

        textView.withStyle(.nonSelectable)
        textView.backgroundColor = .clear
        textView.attributedText = Container.shared.htmlLoader().load(htmlFileName: "CustomECCWarning")

        // Makes hyperlinks in HTML (href) clickable
        textView.isSelectable = true
    }
}
