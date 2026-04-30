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
import SingleLineControllerCombine
import SingleLineControllerController
import SingleLineControllerDIPrimitives
import UIKit
import Zesame

/// Outcome of the keystore-reveal modal.
public enum BackUpKeystoreUserAction {
    /// User tapped the right "Done" bar-button.
    case finished
}

/// View model for the keystore-reveal modal. Surfaces the pretty-printed
/// keystore as a string and handles the copy-to-pasteboard side effect.
public final class BackUpKeystoreViewModel: BaseViewModel<
    BackUpKeystoreUserAction,
    BackUpKeystoreViewModel.InputFromView,
    BackUpKeystoreViewModel.Output
> {
    /// System pasteboard wrapper — injected so tests can record copies.
    @Injected(\.pasteboard) private var pasteboard: Pasteboard

    /// Reactive keystore stream supplied by the coordinator.
    private let keystore: AnyPublisher<Keystore, Never>

    /// Captures the keystore source. Called by the convenience init below.
    init(keystore: AnyPublisher<Keystore, Never>) {
        self.keystore = keystore
    }

    /// Wires:
    /// - Right bar-button → `.finished` navigation step.
    /// - Copy tap → `pasteboard.copy(...)` + toast confirmation.
    override public func transform(input: Input) -> Output {
        func userDid(_ step: NavigationStep) {
            navigator.next(step)
        }

        let keystore: AnyPublisher<String, Never> = keystore.map(\.asPrettyPrintedJSONString).eraseToAnyPublisher()

        [
            input.fromController.rightBarButtonTrigger
                .sink { userDid(.finished) },

            // Pull the *current* keystore string at click-time via withLatestFrom
            // so we don't capture a stale value during init. Sensitive copy →
            // 60s pasteboard expiration (encrypted but still worth limiting
            // residency).
            input.fromView.copyTrigger.withLatestFrom(keystore)
                .sink { [pasteboard] in
                    pasteboard.copy($0, expiringAfter: SensitivePasteboard.expirationSeconds)
                    let toast = Toast(String(localized: .BackUpKeystore.copiedKeystore))
                    input.fromController.toastSubject.send(toast)
                },
        ].forEach { $0.store(in: &cancellables) }

        return Output(
            keystore: keystore
        )
    }
}

extension BackUpKeystoreViewModel {
    /// Convenience init that pulls the keystore directly from a `Wallet` stream.
    convenience init(wallet: AnyPublisher<Wallet, Never>) {
        self.init(keystore: wallet.map(\.keystore).eraseToAnyPublisher())
    }
}

public extension BackUpKeystoreViewModel {
    /// User-event publishers the view-model consumes.
    struct InputFromView {
        /// Fires when the user taps the copy-keystore button.
        let copyTrigger: AnyPublisher<Void, Never>
    }

    /// Reactive bindings the view installs.
    struct Output {
        /// Drives `keystoreTextView.textBinder` with the pretty-printed JSON.
        let keystore: AnyPublisher<String, Never>
    }
}
