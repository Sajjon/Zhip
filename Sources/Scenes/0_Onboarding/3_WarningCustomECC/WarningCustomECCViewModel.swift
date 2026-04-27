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
import Foundation
import SingleLineControllerCombine

// MARK: - WarningCustomECCUserAction

/// Outcomes the ECC warning screen surfaces to its parent coordinator.
enum WarningCustomECCUserAction {
    /// User scrolled to the bottom and accepted.
    case acceptRisks
    /// User tapped "Done" — only available in the Settings-modal context.
    case dismiss
}

// MARK: - WarningCustomECCViewModel

/// View model for the custom-ECC warning screen. Same dual-presentation pattern
/// as `TermsOfServiceViewModel`.
final class WarningCustomECCViewModel: BaseViewModel<
    WarningCustomECCUserAction,
    WarningCustomECCViewModel.InputFromView,
    WarningCustomECCViewModel.Output
> {
    /// Records the acceptance flag in `Preferences`.
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
    /// - "did accept" → record acceptance + emit `.acceptRisks`.
    /// - For the dismissible variant: install a "Done" right bar-button that
    ///   emits `.dismiss`.
    override func transform(input: Input) -> Output {
        func userDid(_ userAction: NavigationStep) {
            navigator.next(userAction)
        }

        // Once the user reaches the bottom, the button stays enabled.
        let isAcceptButtonEnabled: AnyPublisher<Bool, Never> = input.fromView.didScrollToBottom.map { true }
            .eraseToAnyPublisher()

        if isDismissible {
            input.fromController.rightBarButtonContentSubject.onBarButton(.done)
            input.fromController.rightBarButtonTrigger
                .sink { userDid(.dismiss) }.store(in: &cancellables)
        }

        [
            input.fromView.didAcceptTerms.sink { [weak self] in
                // Persist *first* so re-entering onboarding from a kill picks up the new state.
                self?.useCase.didAcceptCustomECCWarning()
                userDid(.acceptRisks)
            },
        ].forEach { $0.store(in: &cancellables) }

        return Output(
            // Hide the accept button in the dismissible variant.
            isAcceptButtonVisible: Just(!isDismissible).eraseToAnyPublisher(),
            isAcceptButtonEnabled: isAcceptButtonEnabled
        )
    }
}

extension WarningCustomECCViewModel {
    /// User-event publishers the view-model consumes.
    struct InputFromView {
        /// Fires once the user scrolls the textView near the bottom.
        let didScrollToBottom: AnyPublisher<Void, Never>
        /// Fires when the user taps the accept button.
        let didAcceptTerms: AnyPublisher<Void, Never>
    }

    /// Reactive bindings the view installs.
    struct Output {
        /// Drives `acceptTermsButton.isVisibleBinder`.
        let isAcceptButtonVisible: AnyPublisher<Bool, Never>
        /// Drives `acceptTermsButton.isEnabledBinder`.
        let isAcceptButtonEnabled: AnyPublisher<Bool, Never>
    }
}
