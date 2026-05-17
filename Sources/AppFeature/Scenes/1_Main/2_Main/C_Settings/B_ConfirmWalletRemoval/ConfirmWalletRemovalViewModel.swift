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

import Combine
import Foundation
import NanoViewControllerCombine
import NanoViewControllerController
import NanoViewControllerCore

// MARK: - User action and navigation steps

/// Outcomes of the wallet-removal confirmation modal.
public enum ConfirmWalletRemovalUserAction: Sendable {
    /// User tapped Cancel — close without removing.
    case cancel
    /// User checked the box and tapped Confirm — coordinator will wipe + finish.
    case confirm
}

// MARK: - ConfirmWalletRemovalViewModel

/// View model for the wallet-removal confirmation. Trivial wiring: cancel-tap
/// emits `.cancel`, confirm-tap emits `.confirm`, button gated on the checkbox.
/// The destructive wipe lives in `SettingsCoordinator.toChooseWallet()` so the
/// dismiss animation can finish before the data is gone.
public final class ConfirmWalletRemovalViewModel: BaseViewModel<
    ConfirmWalletRemovalUserAction,
    ConfirmWalletRemovalViewModel.InputFromView,
    ConfirmWalletRemovalViewModel.Publishers
> {
    /// Wires cancel + confirm taps to navigation steps; gates the confirm
    /// button on the "I have backed up" checkbox.
    override public func transform(input: Input) -> Output<Publishers, NavigationStep> {
        func userDid(_ userAction: NavigationStep) {
            navigator.next(userAction)
        }

        // MARK: Navigate

        [
            input.fromController.leftBarButtonTrigger
                .sink { userDid(.cancel) },

            input.fromView.confirmTrigger
                .sink { userDid(.confirm) },
        ].forEach { $0.store(in: &cancellables) }

        // MARK: Return output

        return Output(
            publishers: Publishers(
                isConfirmButtonEnabled: input.fromView.isWalletBackedUpCheckboxChecked
            ),
            navigation: navigator.navigation
        )
    }
}

public extension ConfirmWalletRemovalViewModel {
    /// User-event publishers the view-model consumes.
    struct InputFromView {
        /// Fires when the user taps Confirm.
        let confirmTrigger: AnyPublisher<Void, Never>
        /// Latest state of the "I have backed up" checkbox.
        let isWalletBackedUpCheckboxChecked: AnyPublisher<Bool, Never>
    }

    /// Reactive bindings the view installs.
    struct Publishers {
        /// Drives `confirmButton.isEnabledBinder`.
        let isConfirmButtonEnabled: AnyPublisher<Bool, Never>
    }
}
