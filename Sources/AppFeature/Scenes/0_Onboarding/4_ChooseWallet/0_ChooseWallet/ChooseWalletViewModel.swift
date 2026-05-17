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
import NanoViewControllerController
import NanoViewControllerCore
import NanoViewControllerNavigation

// MARK: - ChooseWalletUserAction

/// Outcomes the chooser screen surfaces to `ChooseWalletCoordinator`.
public enum ChooseWalletUserAction: Sendable {
    /// User tapped "Create new wallet" — coordinator presents the create flow.
    case createNewWallet
    /// User tapped "Restore wallet" — coordinator presents the restore flow.
    case restoreWallet
}

// MARK: - ChooseWalletViewModel

/// View model for the chooser screen. The screen has no UI state to bind —
/// `Publishers` is empty — so `transform(input:)` only wires the two button taps
/// to navigation steps.
public final class ChooseWalletViewModel: AbstractViewModel<
    ChooseWalletViewModel.InputFromView,
    ChooseWalletViewModel.Publishers,
    ChooseWalletUserAction
> {
    /// Wires both button taps directly to navigator steps and returns an empty `Publishers`.
    override public func transform(input: Input) -> Output<Publishers, NavigationStep> {
        let navigator = Navigator<NavigationStep>()

        return Output(
            publishers: Publishers(),
            navigation: navigator.navigation
        ) {
            input.fromView.createNewWalletTrigger
                .sink { [navigator] in navigator.next(.createNewWallet) }

            input.fromView.restoreWalletTrigger
                .sink { [navigator] in navigator.next(.restoreWallet) }
        }
    }
}

public extension ChooseWalletViewModel {
    /// User-event publishers the view-model consumes.
    struct InputFromView {
        /// Fires when the user taps "Create new wallet".
        let createNewWalletTrigger: AnyPublisher<Void, Never>
        /// Fires when the user taps "Restore wallet".
        let restoreWalletTrigger: AnyPublisher<Void, Never>
    }

    /// No outputs — the screen is entirely static.
    struct Publishers {}
}
