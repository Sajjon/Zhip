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

import Combine
import SingleLineControllerCombine
import UIKit
import Validation

extension InputPincodeView {
    /// Re-exports the field's `becomeFirstResponderBinder` so scenes can
    /// reactively focus the input without reaching through `pinField`.
    var becomeFirstResponderBinder: Binder<Void> {
        pinField.becomeFirstResponderBinder
    }

    /// Re-exports the field's pincode publisher. Emits the parsed `Pincode`
    /// value (or `nil` while incomplete) on each digit change.
    var pincodePublisher: AnyPublisher<Pincode?, Never> {
        pinField.pincodePublisher
    }

    /// Reactive sink that drives `validate(_:)` from a publisher of validation
    /// results — the standard hook used by `populate(with:)` in pincode scenes.
    var validationBinder: Binder<AnyValidation> {
        Binder<AnyValidation>(self) { (view: InputPincodeView, validation: AnyValidation) in
            view.applyValidation(validation)
        }
    }
}
