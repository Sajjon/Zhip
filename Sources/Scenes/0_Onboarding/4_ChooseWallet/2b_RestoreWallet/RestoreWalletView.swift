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
import Zesame

/// Local typealias to avoid the long `RestoreWalletViewModel.InputFromView.Segment` mouthful.
private typealias Segment = RestoreWalletViewModel.InputFromView.Segment

// MARK: - RestoreWalletView

/// Wallet-restore screen with a segmented control between two restore methods.
/// Both sub-views (`RestoreUsingPrivateKeyView`, `RestoreUsingKeystoreView`)
/// are added to the same container — visibility flips based on the segment.
final class RestoreWalletView: ScrollableStackViewOwner {
    /// Holds the segment-change subscription that drives sub-view visibility.
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Subviews

    /// Segmented control: keystore vs private key.
    private lazy var restorationMethodSegmentedControl = UISegmentedControl()
    /// Header label whose text follows the selected segment.
    private lazy var headerLabel = UILabel()
    /// Embedded sub-view for private-key restore.
    private lazy var restoreUsingPrivateKeyView = RestoreUsingPrivateKeyView()
    /// Embedded sub-view for keystore restore. `fileprivate` so the
    /// `keystoreRestorationValidatino` binder can flip its error state.
    fileprivate lazy var restoreUsingKeyStoreView = RestoreUsingKeystoreView()
    /// Container hosting both sub-views; visibility toggles between them.
    private lazy var containerView = UIView()
    /// Bottom restore CTA — shows a spinner during decryption. `fileprivate` so
    /// the validation binder can disable it on keystore-error.
    fileprivate lazy var restoreWalletButton = ButtonWithSpinner()

    /// Vertical layout: header, container with sub-views, restore CTA.
    lazy var stackViewStyle = UIStackView.Style([
        headerLabel,
        containerView,
        restoreWalletButton,
    ], spacing: 8)

    /// Override-hook from `ScrollableStackViewOwner` — wires styling.
    override func setup() {
        setupSubviews()
    }

    /// Custom scroll-view constraints that leave room above the scroll for
    /// the segmented control (which sits *outside* the scrollable stack).
    override func setupScrollViewConstraints() {
        scrollView.bottomToSuperview()
        scrollView.leadingToSuperview()
        scrollView.trailingToSuperview()
    }
}

// MARK: - ViewModelled

extension RestoreWalletView: ViewModelled {
    typealias ViewModel = RestoreWalletViewModel

    /// Surfaces the selected segment, both sub-view restore-payload streams,
    /// and the restore-button tap. The segment publisher is `prepend(...)`-ed
    /// with the current value so subscribers see the initial state, not just changes.
    var inputFromView: InputFromView {
        let segmentValue = restorationMethodSegmentedControl.publisher(for: .valueChanged)
            .map { [weak restorationMethodSegmentedControl] _ in
                restorationMethodSegmentedControl?.selectedSegmentIndex ?? 0
            }
            .prepend(restorationMethodSegmentedControl.selectedSegmentIndex)
            .eraseToAnyPublisher()
        return InputFromView(
            selectedSegment: segmentValue.map { Segment(rawValue: $0) }.filterNil().eraseToAnyPublisher(),
            keyRestorationUsingPrivateKey: restoreUsingPrivateKeyView.viewModelOutput.keyRestoration,
            keyRestorationUsingKeystore: restoreUsingKeyStoreView.viewModelOutput.keyRestoration,
            restoreTrigger: restoreWalletButton.tapPublisher
        )
    }

    /// Binds header text, button loading/enabled states, and the keystore-error
    /// "soft-redirect" binder (see `keystoreRestorationValidatino` below).
    func populate(with viewModel: ViewModel.Output) -> [AnyCancellable] {
        [
            viewModel.headerLabel --> headerLabel.textBinder,
            viewModel.isRestoring --> restoreWalletButton.isLoadingBinder,
            viewModel.isRestoreButtonEnabled --> restoreWalletButton.isEnabledBinder,
            viewModel.keystoreRestorationError --> keystoreRestorationValidatino,
        ]
    }

    /// Composite binder that handles the "keystore restore failed with wrong password"
    /// case: routes the error to the keystore sub-view, force-switches the
    /// segmented control to the keystore tab, and disables the restore button
    /// (the user must edit the password to re-enable it).
    var keystoreRestorationValidatino: Binder<AnyValidation> {
        Binder<AnyValidation>(self) {
            $0.restoreUsingKeyStoreView.restorationErrorValidation($1)
            $0.selectSegment(.keystore)
            $0.restoreWalletButton.isEnabled = false
        }
    }
}

// MARK: - Private

private extension RestoreWalletView {
    /// Styling pass — header style, container holding both sub-views overlaid,
    /// primary restore button (initially disabled), and segmented-control setup.
    func setupSubviews() {
        headerLabel.withStyle(.header)
        containerView.translatesAutoresizingMaskIntoConstraints = false

        // Overlay both sub-views in the same container; visibility flips below.
        for item in [restoreUsingPrivateKeyView, restoreUsingKeyStoreView] {
            item.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(item)
            item.edgesToSuperview()
        }

        restoreWalletButton.withStyle(.primary) {
            $0.title(String(localized: .RestoreWallet.restore))
                .disabled()
        }

        setupSegmentedControl()
    }

    /// Builds the segmented control (positioned *above* the scroll view, not
    /// inside the scrollable stack), styles its segments teal-on-white, and
    /// wires the value-change publisher to flip sub-view visibility.
    func setupSegmentedControl() {
        restorationMethodSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        addSubview(restorationMethodSegmentedControl)
        restorationMethodSegmentedControl.topToSuperview(offset: 10, usingSafeArea: true)
        restorationMethodSegmentedControl.centerXToSuperview()
        restorationMethodSegmentedControl.bottomToTop(of: scrollView)

        func add(segment: Segment, titled title: String) {
            restorationMethodSegmentedControl.insertSegment(withTitle: title, at: segment.rawValue, animated: false)
        }

        restorationMethodSegmentedControl.selectedSegmentTintColor = .teal

        restorationMethodSegmentedControl.addBorder(.init(color: .teal, width: 1))

        let whiteFontAttributes = [
            NSAttributedString.Key.font: UIFont.hint,
            NSAttributedString.Key.foregroundColor: UIColor.white,
        ]

        let tealFontAttributes = [
            NSAttributedString.Key.font: UIFont.hint,
            NSAttributedString.Key.foregroundColor: UIColor.teal,
        ]

        restorationMethodSegmentedControl.setTitleTextAttributes(whiteFontAttributes, for: .selected)
        restorationMethodSegmentedControl.setTitleTextAttributes(tealFontAttributes, for: .normal)

        add(segment: .keystore, titled: String(localized: .RestoreWallet.keystoreSegment))
        add(segment: .privateKey, titled: String(localized: .RestoreWallet.privateKeySegment))

        restorationMethodSegmentedControl.publisher(for: .valueChanged)
            .map { [weak restorationMethodSegmentedControl] _ in restorationMethodSegmentedControl?.selectedSegmentIndex ?? 0 }
            .map { Segment(rawValue: $0) }
            .filterNil()
            .sink { [weak self] in self?.switchToViewFor(selectedSegment: $0) }.store(in: &cancellables)

        selectSegment(.privateKey)
    }

    /// Toggles `isHidden` on the two overlaid sub-views based on the segment.
    func switchToViewFor(selectedSegment: Segment) {
        switch selectedSegment {
        case .privateKey:
            restoreUsingPrivateKeyView.isHidden = false
            restoreUsingKeyStoreView.isHidden = true
        case .keystore:
            restoreUsingPrivateKeyView.isHidden = true
            restoreUsingKeyStoreView.isHidden = false
        }
    }

    /// Programmatically picks a segment (and fires `.valueChanged` so the
    /// sub-view-switch publisher reacts). Used by the keystore-error binder
    /// to force-redirect to the keystore tab when a wrong-password error fires.
    func selectSegment(_ segment: Segment) {
        restorationMethodSegmentedControl.selectedSegmentIndex = segment.rawValue
        restorationMethodSegmentedControl.sendActions(for: .valueChanged)
    }
}
