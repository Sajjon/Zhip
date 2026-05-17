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
import NanoViewControllerCore
import NanoViewControllerController

// MARK: TermsOfServiceNavigation

/// Outcomes the Terms of Service screen surfaces to its parent coordinator.
public enum TermsOfServiceNavigation: Sendable {
    /// User scrolled to the bottom and tapped "Accept".
    case acceptTermsOfService
    /// User tapped the right bar-button "Done" — only available in the
    /// dismissible (Settings-modal) presentation context.
    case dismiss
}

// MARK: - TermsOfServiceViewModel

/// View model for the Terms of Service screen.
///
/// Two presentation contexts share this view-model:
/// 1. **Onboarding** — `isDismissible = false`. The accept button is shown,
///    enabled only after the user scrolls to the bottom.
/// 2. **Settings modal** — `isDismissible = true`. A right bar-button "Done"
///    appears so the user can close the modal; the accept button is hidden.
public final class TermsOfServiceViewModel: BaseViewModel<
    TermsOfServiceNavigation,
    TermsOfServiceViewModel.InputFromView,
    TermsOfServiceViewModel.Publishers
> {
    /// Records the Terms acceptance flag in `Preferences`.
    private let useCase: OnboardingUseCase
    /// `true` for the Settings-modal presentation, `false` for onboarding.
    private let isDismissible: Bool

    /// Captures the use case + presentation context.
    init(useCase: OnboardingUseCase, isDismissible: Bool) {
        self.useCase = useCase
        self.isDismissible = isDismissible
    }

    /// Wires:
    /// - "scrolled to bottom" → enable accept button (latches `true`).
    /// - "did accept" → record acceptance + emit `.acceptTermsOfService`.
    /// - For the dismissible variant: install a "Done" right bar-button that
    ///   emits `.dismiss`.
    override public func transform(input: Input) -> Output<Publishers, NavigationStep> {
        func userDid(_ userAction: NavigationStep) {
            navigator.next(userAction)
        }

        // Once the user reaches the bottom, the button stays enabled — no
        // need to track scroll position continuously.
        let isAcceptButtonEnabled: AnyPublisher<Bool, Never> = input.fromView.didScrollToBottom.map { true }
            .eraseToAnyPublisher()

        if isDismissible {
            // Settings-modal context: install a "Done" right-bar button so the
            // user can close the modal without accepting (they've already accepted earlier).
            input.fromController.rightBarButtonContentSubject.onBarButton(.done)
            input.fromController.rightBarButtonTrigger
                .sink { userDid(.dismiss) }.store(in: &cancellables)
        }

        [
            input.fromView.didAcceptTerms.sink { [weak self] in
                // Persist *first* so re-entering onboarding from a kill picks up the new state.
                self?.useCase.didAcceptTermsOfService()
                userDid(.acceptTermsOfService)
            },
        ].forEach { $0.store(in: &cancellables) }

        return Output(
            publishers: Publishers(
                // Hide the accept button in the dismissible (Settings-modal) variant.
                isAcceptButtonVisible: Just(!isDismissible).eraseToAnyPublisher(),
                isAcceptButtonEnabled: isAcceptButtonEnabled
            ),
            navigation: navigator.navigation
        )
    }
}

public extension TermsOfServiceViewModel {
    /// User-event publishers the view-model consumes.
    struct InputFromView {
        /// Fires once the user scrolls the textView near the bottom.
        let didScrollToBottom: AnyPublisher<Void, Never>
        /// Fires when the user taps the accept button.
        let didAcceptTerms: AnyPublisher<Void, Never>
    }

    /// Reactive bindings the view installs.
    struct Publishers {
        /// Drives `acceptTermsButton.isVisibleBinder`.
        let isAcceptButtonVisible: AnyPublisher<Bool, Never>
        /// Drives `acceptTermsButton.isEnabledBinder`.
        let isAcceptButtonEnabled: AnyPublisher<Bool, Never>
    }
}
