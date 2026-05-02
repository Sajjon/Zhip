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
import NanoViewControllerCombine
import NanoViewControllerController
import Validation

// MARK: - ConfirmNewPincodeUserAction

/// Outcomes of the confirmation step.
public enum ConfirmNewPincodeUserAction {
    /// User retyped a matching pincode and tapped confirm — pincode persisted by the use case.
    case confirmPincode
    /// User tapped the right-bar "Skip" button.
    case skip
}

// MARK: - ConfirmNewPincodeViewModel

/// View model for the pincode confirmation step. Validates the re-entered
/// pincode against the one picked in the previous step; on success persists
/// it via `PincodeUseCase` and emits `.confirmPincode`.
public final class ConfirmNewPincodeViewModel: BaseViewModel<
    ConfirmNewPincodeUserAction,
    ConfirmNewPincodeViewModel.InputFromView,
    ConfirmNewPincodeViewModel.Output
> {
    /// Used to persist the confirmed pincode.
    private let useCase: PincodeUseCase
    /// The pincode chosen in the prior step that the user is now retyping.
    private let unconfirmedPincode: Pincode

    /// Captures the use case + the pincode to confirm against.
    init(useCase: PincodeUseCase, confirm unconfirmedPincode: Pincode) {
        self.useCase = useCase
        self.unconfirmedPincode = unconfirmedPincode
    }

    /// Wires real-time validation, the confirm-tap (persists + emits), the
    /// skip-tap, and the (matches && checkbox-checked) gate for the CTA.
    override public func transform(input: Input) -> Output {
        func userDid(_ step: NavigationStep) {
            navigator.next(step)
        }

        let validator = InputValidator(existingPincode: unconfirmedPincode)

        let pincodeValidationValue: AnyPublisher<PincodeValidator.ValidationResult, Never> = input.fromView.pincode
            .map {
                validator.validate(unconfirmedPincode: $0)
            }.eraseToAnyPublisher()
        let isConfirmPincodeEnabled: AnyPublisher<Bool, Never> = pincodeValidationValue.map(\.isValid)
            .combineLatest(input.fromView.isHaveBackedUpPincodeCheckboxChecked) { isPincodeValid, isBackedUpChecked in
                isPincodeValid && isBackedUpChecked
            }.eraseToAnyPublisher()

        [
            input.fromView.confirmedTrigger.withLatestFrom(pincodeValidationValue.map(\.value).filterNil())
                .sink { [weak self] in
                    self?.useCase.userChoose(pincode: $0)
                    userDid(.confirmPincode)
                },

            input.fromController.rightBarButtonTrigger
                .sink { userDid(.skip) },
        ].forEach { $0.store(in: &cancellables) }

        return Output(
            pincodeValidation: pincodeValidationValue.map(\.validation).eraseToAnyPublisher(),
            isConfirmPincodeEnabled: isConfirmPincodeEnabled,
            inputBecomeFirstResponder: input.fromController.viewDidAppear
        )
    }
}

public extension ConfirmNewPincodeViewModel {
    /// User-event publishers the view-model consumes.
    struct InputFromView {
        /// Latest re-entered pincode (`nil` while incomplete).
        let pincode: AnyPublisher<Pincode?, Never>
        /// `true` whenever the "I have backed up" checkbox is checked.
        let isHaveBackedUpPincodeCheckboxChecked: AnyPublisher<Bool, Never>
        /// Fires when the user taps the confirm CTA.
        let confirmedTrigger: AnyPublisher<Void, Never>
    }

    /// Reactive bindings the view installs.
    struct Output {
        /// Drives the pincode input's validation styling.
        let pincodeValidation: AnyPublisher<AnyValidation, Never>
        /// Drives the confirm-button enabled state — true iff matching && checked.
        let isConfirmPincodeEnabled: AnyPublisher<Bool, Never>
        /// Pulses on `viewDidAppear` to put the input in focus.
        let inputBecomeFirstResponder: AnyPublisher<Void, Never>
    }

    /// Adapts `PincodeValidator` to the screen's needs by capturing the
    /// expected pincode and delegating validation to the shared validator.
    internal struct InputValidator {
        private let existingPincode: Pincode
        private let pincodeValidator = PincodeValidator(settingNew: true)

        /// Captures the pincode the user is supposed to retype.
        init(existingPincode: Pincode) {
            self.existingPincode = existingPincode
        }

        /// Compares `unconfirmedPincode` against the captured `existingPincode`.
        func validate(unconfirmedPincode: Pincode?) -> PincodeValidator.ValidationResult {
            pincodeValidator.validate(input: (unconfirmedPincode, existingPincode))
        }
    }
}

/// Generic pincode equality validator. `settingNew` flips the error variant
/// so the unlock screen and the confirm screen can render different copy
/// (currently both use the same string but the case carries the distinction
/// for future copy changes).
public struct PincodeValidator: InputValidator {
    public typealias Output = Pincode
    /// Mismatch error.
    public enum Error: InputError {
        /// Re-entered pincode doesn't match the expected one. `settingNew`
        /// tags whether this is the confirm-new step or the unlock step.
        case incorrectPincode(settingNew: Bool)
    }

    private let settingNew: Bool

    /// `settingNew: true` for the confirm-new step; `false` for the unlock screen.
    init(settingNew: Bool = false) {
        self.settingNew = settingNew
    }

    /// Compares `unconfirmed` against `existing`. Returns `.empty` for nil
    /// (still typing), `.error` for a mismatch, `.valid` on match.
    public func validate(input: (unconfirmed: Pincode?, existing: Pincode)) -> ValidationResult {
        let pincode = input.existing

        guard let unconfirmed = input.unconfirmed else {
            return .invalid(.empty)
        }

        guard unconfirmed == pincode else {
            return .invalid(.error(Error.incorrectPincode(settingNew: settingNew)))
        }
        return .valid(pincode)
    }
}

public extension PincodeValidator.Error {
    /// Localized error string. Both `settingNew` branches currently render
    /// the same copy; the switch is kept for future copy divergence.
    var errorMessage: String {
        switch self {
        case let .incorrectPincode(settingNew):
            if settingNew {
                String(localized: .Errors.pincodesDoNotMatch)
            } else {
                String(localized: .Errors.pincodesDoNotMatch)
            }
        }
    }
}
