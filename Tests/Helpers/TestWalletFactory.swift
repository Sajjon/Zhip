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

@testable import AppFeature
import Foundation
import Zesame

/// Produces Zhip `Wallet` fixtures for tests using deterministic, fast KDF
/// parameters (iterations=1) so the expensive PBKDF2 derivation never dominates
/// test runtime.
enum TestWalletFactory {
    static let testPassword = "apabanan123"

    /// Builds a test `Wallet` from a known private key. Uses PBKDF2 with
    /// `iterations=1` so the keystore builds in <100ms. Crashes if construction
    /// fails, which can only happen if the hard-coded private key or KDF params
    /// are invalid — both are test-static and cannot fail at runtime.
    static func makeWallet(origin: AppFeature.Wallet.Origin = .generatedByThisApp) -> AppFeature.Wallet {
        do {
            let privateKey = try PrivateKey(
                rawRepresentation: Data(hex: "0E891B9DFF485000C7D1DC22ECF3A583CC50328684321D61947A86E57CF6C638")
            )
            let kdfParams = try KDFParams(iterations: 1)
            let keystore = try Keystore.from(
                privateKey: privateKey,
                encryptBy: testPassword,
                kdf: .pbkdf2,
                kdfParams: kdfParams
            )
            return AppFeature.Wallet(wallet: Zesame.Wallet(keystore: keystore), origin: origin)
        } catch {
            fatalError("TestWalletFactory failed: \(error)")
        }
    }
}
