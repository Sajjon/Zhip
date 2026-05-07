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
import Factory
import NanoViewControllerCombine
import NanoViewControllerCore
import NanoViewControllerController
import NanoViewControllerDIPrimitives
import UIKit
import Zesame

/// Outcome of the revealed-keypair display screen.
public enum BackUpRevealedKeyPairUserAction: Sendable {
    /// User tapped the right "Done" bar-button.
    case finish
}

/// Renders a `KeyPair` as two hex strings + handles copy-to-pasteboard side effects.
public final class BackUpRevealedKeyPairViewModel: BaseViewModel<
    BackUpRevealedKeyPairUserAction,
    BackUpRevealedKeyPairViewModel.InputFromView,
    BackUpRevealedKeyPairViewModel.Output
> {
    /// System pasteboard wrapper — injected so tests can record copies.
    @Injected(\.pasteboard) private var pasteboard: Pasteboard

    /// The decrypted key pair to display. Captured at init since it doesn't change after reveal.
    private let keyPair: KeyPair

    /// Captures the key pair to display.
    init(keyPair: KeyPair) {
        self.keyPair = keyPair
    }

    /// Converts the key pair to hex strings, wires the right "Done" bar-button to
    /// `.finish`, and routes copy taps to pasteboard + toast.
    override public func transform(input: Input) -> Output {
        func userDid(_ step: NavigationStep) {
            navigator.next(step)
        }

        let keyPair = Just(keyPair).eraseToAnyPublisher()

        // Hex-encode each key for display. Private key uses raw representation;
        // public key uses x963 (uncompressed) — the format other Zilliqa tools expect.
        let privateKey: AnyPublisher<String, Never> = keyPair.map(\.privateKey.rawRepresentation.asHex)
            .eraseToAnyPublisher()
        let publicKeyUncompressed: AnyPublisher<String, Never> = keyPair.map(\.publicKey.x963Representation.asHex)
            .eraseToAnyPublisher()

        [
            input.fromController.rightBarButtonTrigger
                .sink { userDid(.finish) },

            // Private key is the most sensitive material in the app — write
            // it to the pasteboard with a 60s expiration so it does NOT sit
            // around for clipboard managers, Universal Clipboard sync to a
            // Mac, or other apps to harvest. The user can paste it into a
            // password manager within that window.
            input.fromView.copyPrivateKeyTrigger.withLatestFrom(privateKey) { $1 }
                .sink { [pasteboard] privateKeyText in
                    // pasteboard.copy + Toast init are @MainActor — hop
                    // explicitly because the Combine sink closure is @Sendable.
                    mainActorOnly {
                        pasteboard.copy(privateKeyText, expiringAfter: SensitivePasteboard.expirationSeconds)
                        input.fromController.toastSubject
                            .send(Toast(String(localized: .BackUpRevealedKeyPair.copiedPrivateKey)))
                    }
                },

            // Public key isn't sensitive but pair the same expiration for
            // consistency on this screen — anything copied here is in the
            // "I'm-actively-handling-keys" mental mode.
            input.fromView.copyPublicKeyTrigger.withLatestFrom(publicKeyUncompressed) { $1 }
                .sink { [pasteboard] publicKeyText in
                    mainActorOnly {
                        pasteboard.copy(publicKeyText, expiringAfter: SensitivePasteboard.expirationSeconds)
                        input.fromController.toastSubject
                            .send(Toast(String(localized: .BackUpRevealedKeyPair.copiedPublicKey)))
                    }
                },
        ].forEach { $0.store(in: &cancellables) }

        return Output(
            privateKey: privateKey,
            publicKeyUncompressed: publicKeyUncompressed
        )
    }
}

public extension BackUpRevealedKeyPairViewModel {
    /// User-event publishers the view-model consumes.
    struct InputFromView {
        /// Fires when the user taps "Copy" next to the private key.
        let copyPrivateKeyTrigger: AnyPublisher<Void, Never>
        /// Fires when the user taps "Copy" next to the public key.
        let copyPublicKeyTrigger: AnyPublisher<Void, Never>
    }

    /// Reactive bindings the view installs.
    struct Output {
        /// Hex-encoded private key — drives `privateKeyTextView.valueBinder`.
        let privateKey: AnyPublisher<String, Never>
        /// Hex-encoded uncompressed public key — drives `publicKeyUncompressedTextView.valueBinder`.
        let publicKeyUncompressed: AnyPublisher<String, Never>
    }
}
