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
import Foundation
import SingleLineControllerCore

// MARK: - UnlockAppWithPincodeUserAction

/// Outcome of the unlock screen — the only thing the user can do here is unlock.
enum UnlockAppWithPincodeUserAction {
    /// Either pincode-match or successful biometrics unlocked the app.
    case unlockApp
}

// MARK: - UnlockAppWithPincodeViewModel

/// View model for the pincode-unlock screen.
///
/// Two unlock paths share the `.unlockApp` outcome:
/// 1. Pincode entry that matches the saved pincode.
/// 2. Successful Face/Touch ID prompt fired automatically on `viewDidAppear`.
final class UnlockAppWithPincodeViewModel: BaseViewModel<
    UnlockAppWithPincodeUserAction,
    UnlockAppWithPincodeViewModel.InputFromView,
    UnlockAppWithPincodeViewModel.Output
> {
    /// Read-only pincode access for comparison.
    @Injected(\.pincodeUseCase) private var pincodeUseCase: PincodeUseCase
    /// Optional biometric prompt — `authenticate()` returns `Bool` success.
    @Injected(\.biometricsAuthenticator) private var biometricsAuthenticator: BiometricsAuthenticator

    /// The persisted pincode the user must match. Crashes if missing — that
    /// would mean the unlock screen was shown without a configured pincode.
    private lazy var pincode: Pincode = {
        guard let pincode = pincodeUseCase.pincode else {
            incorrectImplementation("Should have pincode set")
        }
        return pincode
    }()

    /// Wires real-time pincode comparison + biometric prompt; either path
    /// succeeding fires `.unlockApp`.
    override func transform(input: Input) -> Output {
        func userDid(_ userAction: NavigationStep) {
            navigator.next(userAction)
        }

        let validator = InputValidator(existingPincode: pincode)

        let pincodeValidationValue = input.fromView.pincode.map {
            validator.validate(unconfirmedPincode: $0)
        }

        let biometricsAuthenticator = biometricsAuthenticator
        // Capture locally so we don't pull `self` into the merge below.
        let unlockUsingBiometrics = {
            biometricsAuthenticator.authenticate()
                .filter { $0 }
                .mapToVoid()
                .eraseToAnyPublisher()
        }

        // `.prefix(1)` so the biometric prompt fires only on the *first*
        // viewDidAppear — without it, dismissing the prompt and returning to
        // the screen (rotation, app-switcher, etc.) re-triggers it.
        let unlockUsingBiometricsTrigger = input.fromController.viewDidAppear.prefix(1)

        [
            // `.first()` so only the *first* unlock signal is honoured — without
            // it, biometrics succeeding while the user was mid-pincode entry
            // would fire `userDid(.unlockApp)` twice and double-trigger the
            // navigation transition. The biometric prompt fires on
            // viewDidAppear (not willAppear) so the system alert isn't
            // competing with our presentation animation.
            pincodeValidationValue.filter(\.isValid).mapToVoid()
                .merge(with: unlockUsingBiometricsTrigger.flatMapLatest { unlockUsingBiometrics() })
                .first()
                .sinkOnMain { userDid(.unlockApp) },
        ].forEach { $0.store(in: &cancellables) }

        return Output(
            // Focus on viewWillAppear so the keyboard is up before the screen is fully visible.
            inputBecomeFirstResponder: input.fromController.viewWillAppear,
            pincodeValidation: pincodeValidationValue.map(\.validation).eraseToAnyPublisher()
        )
    }
}

extension UnlockAppWithPincodeViewModel {
    /// User-event publishers the view-model consumes.
    struct InputFromView {
        /// Latest pincode value from the input view.
        let pincode: AnyPublisher<Pincode?, Never>
    }

    /// Reactive bindings the view installs.
    struct Output {
        /// Pulses on viewWillAppear to put the input in focus.
        let inputBecomeFirstResponder: AnyPublisher<Void, Never>
        /// Drives the input's validation styling.
        let pincodeValidation: AnyPublisher<AnyValidation, Never>
    }

    /// Adapts `PincodeValidator(settingNew: false)` to the screen — captures
    /// the saved pincode and delegates each validation to the shared validator.
    struct InputValidator {
        private let existingPincode: Pincode
        private let pincodeValidator = PincodeValidator(settingNew: false)

        /// Captures the saved pincode the user must match.
        init(existingPincode: Pincode) {
            self.existingPincode = existingPincode
        }

        /// Compares `unconfirmedPincode` against the saved one.
        func validate(unconfirmedPincode: Pincode?) -> PincodeValidator.ValidationResult {
            pincodeValidator.validate(input: (unconfirmedPincode, existingPincode))
        }
    }
}

