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
import LocalAuthentication

/// Abstracts `LAContext`-based biometric authentication. Exists behind a
/// protocol so view-models can trigger Face ID / Touch ID prompts without
/// touching `LocalAuthentication` directly, and so unit tests register a
/// no-op implementation that never shows a real system prompt.
public protocol BiometricsAuthenticator: AnyObject {
    /// Prompts the user for biometric authentication. Emits exactly once with
    /// `true` when the user authenticates successfully and `false` for every
    /// other outcome (policy unavailable, cancel, failure). Always completes —
    /// never leaves dangling subscriptions under `flatMap`.
    func authenticate() -> AnyPublisher<Bool, Never>
}

/// Production implementation backed by `LAContext` against
/// `.deviceOwnerAuthenticationWithBiometrics`.
public final class LAContextBiometricsAuthenticator: BiometricsAuthenticator {
    init() {}

    public func authenticate() -> AnyPublisher<Bool, Never> {
        Deferred {
            Future<Bool, Never> { promise in
                let context = LAContext()
                context.localizedFallbackTitle = String(localized: .UnlockApp.biometricsFallback)
                let reasonString = String(localized: .UnlockApp.biometricsReason)
                var authError: NSError?
                guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) else {
                    promise(.success(false))
                    return
                }
                // `evaluatePolicy`'s reply closure is `@Sendable` (LAContext
                // can dispatch off-main). Combine's `Future.promise` type
                // `(Result<Bool, Never>) -> Void` is not marked `Sendable`,
                // so capturing it directly triggers a Swift 6 warning. Box
                // it through `SendablePromise` (one well-documented
                // `@unchecked` site) so the capture is type-safe.
                let box = SendablePromise(promise)
                context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: reasonString
                ) { didAuth, _ in
                    box.value(.success(didAuth))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

/// Sendable box for a Combine `Future.promise`. The underlying closure type
/// `(Result<T, E>) -> Void` is not `Sendable` (`Result` itself is, but
/// closures are nominally non-Sendable until proven otherwise).
///
/// `@unchecked Sendable` is safe here because:
///   * `Future`'s promise is documented to be safe to call from any thread
///     — Combine forwards through an internal `os_unfair_lock`.
///   * `value` is `let`-bound and never reassigned after init.
///
/// Concentrated as a private helper so the unchecked-Sendable claim has
/// exactly one site.
private struct SendablePromise<T>: @unchecked Sendable {
    let value: (Result<T, Never>) -> Void
    init(_ value: @escaping (Result<T, Never>) -> Void) { self.value = value }
}
