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

import NanoViewControllerSceneViews
import Zesame

// MARK: - Retroactive Sendable for NanoViewController types

/// `SectionModel<Section, Item>` is a value-type wrapper over `Section` and
/// `[Item]`; trivially `Sendable` in practice. Swift requires
/// `@unchecked Sendable` for retroactive conformance to a generic struct
/// declared in another module — even when the storage is provably safe.
///
/// Removal plan: file as a follow-up to NVC to add native conditional
/// `Sendable` conformance (`extension SectionModel: Sendable where Section:
/// Sendable, Item: Sendable {}` in NVC's own source), then drop this.
extension SectionModel: @retroactive @unchecked Sendable {}

// MARK: - Retroactive @unchecked Sendable for Zesame value types
//
// **Why this file exists:**
//
// Zesame predates Swift Concurrency and has not been audited for `Sendable`
// conformance upstream. Several of its value types appear in Zhip code paths
// that cross actor boundaries — specifically:
//
//  - The global `let network: Network = .mainnet` in `Container.swift`
//    (read by `@MainActor`-isolated callers and the `@Sendable` factory
//    closures Factory uses for resolution).
//  - `BaseViewModel.NavigationStep`/`UserAction` enums whose associated
//    values include Zesame leaf types (`KeyPair`, `Payment`,
//    `TransactionResponse`) — `Navigator<Step>` constrains `Step: Sendable`.
//  - Zhip's wrapper types (`Zhip.Wallet`, `Zhip.TransactionIntent`,
//    `Zhip.Pincode`) which embed Zesame value types as stored properties;
//    Zhip's own `Sendable` conformance synthesises only if the embedded
//    type is `Sendable`.
//
// **Why retroactive `@unchecked Sendable` and not something safer:**
//
//  1. We cannot edit Zesame from here. Adding the conformance upstream is
//     the correct long-term fix and a tracked follow-up.
//  2. Synthesised `Sendable` is not available across module boundaries for
//     non-`@frozen` types, even when every stored property is itself
//     `Sendable`-compatible (`String`, `BigInt`, `Data`, etc.).
//  3. `@preconcurrency import Zesame` only downgrades the diagnostic from
//     error to warning; the consumer enums *still* can't conform to
//     `Sendable` because `Sendable` synthesis sees the raw conformance
//     state, not the diagnostic. The `Navigator` constraint is hard.
//
// **Why this is actually safe at runtime:**
//
// Every type below is an immutable value type (struct or enum) in Zesame.
// Their stored properties are themselves value types (`String`, `BigInt`,
// `Data`, etc.) — no class instances, no shared mutable state. Sendability
// of value types comes from "no shared mutable state"; immutable structs
// of immutable fields are trivially safe to read from any actor. The
// `@unchecked` label means the compiler is taking our word for that audit
// — which we have done by reading Zesame's source.
//
// **Concentrated in one file** so reviewers have a single place to verify
// the rationale. Removing any of these once Zesame ships its own
// `Sendable` conformances should be a one-line diff per type.

/// Build-time enum naming the chain target (`.mainnet` etc.). Trivial value
/// type. Used as a global `let` in `Container.swift`.
extension Network: @retroactive @unchecked Sendable {}

/// Hot-wallet keystore + bech32 address pair. All stored fields are immutable
/// (`Keystore` is a struct of `String`/`Data`; `Address` is a string-backed
/// struct). Reading from any actor is trivially safe.
extension Zesame.Wallet: @retroactive @unchecked Sendable {}

/// Bech32 / hex address wrapper. Immutable string-backed value type.
extension Address: @retroactive @unchecked Sendable {}

/// Numeric token amount with associated `Unit`. Immutable struct over
/// `BigInt`. Safe across actors.
extension Amount: @retroactive @unchecked Sendable {}

/// Denomination enum (`.zil`, `.li`, `.qa`). Immutable enum case. Safe
/// across actors.
extension Unit: @retroactive @unchecked Sendable {}

/// Public/private key pair. Both keys are immutable byte-string wrappers.
/// Safe across actors.
extension KeyPair: @retroactive @unchecked Sendable {}

/// Outgoing-payment value type — sender, recipient, amount, gas, nonce. All
/// fields are immutable. Safe across actors.
extension Payment: @retroactive @unchecked Sendable {}

/// Broadcast result returned by `Zesame` after a successful submission —
/// transaction id + originating sender. Immutable; safe across actors.
extension TransactionResponse: @retroactive @unchecked Sendable {}
