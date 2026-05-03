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
import Zesame

/// Default implementation of `CreateWalletUseCase`.
///
/// Forwards to the shared `ZilliqaServiceReactive` via `@Injected` so tests can
/// substitute the service using `Container.shared.zilliqaService.register { ... }`.
public final class DefaultCreateWalletUseCase: CreateWalletUseCase {
    /// The reactive Zesame façade used to derive the keystore. Resolved lazily via
    /// Factory so test doubles can be registered before the use case is invoked.
    @Injected(\.zilliqaService) private var zilliqaService: ZilliqaServiceReactive

    /// No-op designated initializer — all dependencies are resolved through `@Injected`.
    init() {}

    /// Generates a fresh wallet via Zesame using the project-wide default KDF, tags
    /// the result with `.generatedByThisApp` (so the password mode resolves correctly
    /// later), and lifts Zesame's typed error to the protocol's `Swift.Error`.
    public func createNewWallet(encryptionPassword: String) -> AnyPublisher<Wallet, Swift.Error> {
        zilliqaService.createNewWallet(encryptionPassword: encryptionPassword, kdf: .default)
            .map { Wallet(wallet: $0, origin: .generatedByThisApp) }
            .mapError { $0 as Swift.Error }
            // `Zesame.CombineWrapper.callAsync` resumes its `Task { … }` on the
            // cooperative thread pool (it doesn't preserve caller actor
            // isolation). Without an explicit hop, every downstream `.sink`
            // closure in our `@MainActor`-isolated `BaseViewModel.transform`
            // would run off-main and trap on the iOS 26 isolation check the
            // moment it touched a MainActor-isolated symbol (the local
            // `userDid` nested function, or any UIKit binding). Receiving on
            // `DispatchQueue.main` here is the architectural seam that makes
            // every consumer of this use case main-thread-safe by default.
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
