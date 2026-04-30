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

import Foundation
import Zesame

// `Address` is defined in the Zesame package, which doesn't ship `Codable` conformance.
// We add it `@retroactive`-ly here because the app needs to (de)serialize transaction
// intents to/from JSON (QR codes, deep links) where the address is the primary field.

/// `Decodable` retroactive conformance for `Zesame.Address`. See `init(from:)` for shape.
extension Address: @retroactive Decodable {}
/// `Encodable` retroactive conformance for `Zesame.Address`. See `encode(to:)` for shape.
extension Address: @retroactive Encodable {}
public extension Address {
    /// Decodes an address from a single string value.
    ///
    /// The incoming string is `lowercased()` first because Zilliqa Ethereum-style
    /// addresses are case-insensitive but `Address(string:)` is strict — uppercasing
    /// would otherwise be ambiguous with EIP-55-style checksum addresses.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let addressString = try container.decode(String.self).lowercased()
        try self.init(string: addressString)
    }

    /// Encodes the address as an uppercased single string value.
    ///
    /// Uppercasing is the standard hex display form on Zilliqa for the legacy
    /// representation, so consumers (other wallets / explorers) get a familiar
    /// shape on the wire.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(asString.uppercased())
    }
}

/// A user's *intention* to send a transaction — recipient address plus an optional
/// amount, with no signing or broadcasting context attached.
///
/// Used as the data shape for QR codes, deep links, and pre-filled send-screen state.
/// Distinct from `Zesame.Transaction` (which is a fully-formed signed payload).
public struct TransactionIntent: Codable, Equatable {
    /// Destination address of the would-be transaction.
    public let to: Address

    /// Optional pre-filled amount. `nil` means the recipient was specified but the
    /// user is expected to choose the amount themselves on the send screen.
    public let amount: Amount?

    /// Memberwise initializer with `amount` defaulting to `nil`.
    public init(to recipient: Address, amount: Amount? = nil) {
        to = recipient
        self.amount = amount
    }
}

extension TransactionIntent {
    /// Parses a QR-code-payload string into a `TransactionIntent`.
    ///
    /// Two payload shapes are supported, in order of preference:
    /// 1. **Bare address string** — fast path, common for "give me tokens" QR codes
    ///    that omit the amount. Constructs a no-amount intent.
    /// 2. **JSON object** — fallback when the string isn't a valid address.
    ///    Decoded as `TransactionIntent` (so the QR can carry both fields).
    ///
    /// Throws `Error.scannedStringNotAddressNorJson` if neither path succeeds.
    public static func fromScannedQrCodeString(_ scannedString: String) throws -> TransactionIntent {
        do {
            return try TransactionIntent(to: Address(string: scannedString))
        } catch {
            // Address parsing failed — try interpreting the entire string as JSON.
            // If even UTF-8 conversion fails the input was binary garbage.
            guard let json = scannedString.data(using: .utf8) else { throw Error.scannedStringNotAddressNorJson }
            return try JSONDecoder().decode(TransactionIntent.self, from: json)
        }
    }

    /// Failure modes for `fromScannedQrCodeString(_:)`.
    public enum Error: Swift.Error, Equatable {
        /// The scanned string was neither a valid address nor valid JSON for a `TransactionIntent`.
        case scannedStringNotAddressNorJson
    }
}

extension TransactionIntent {
    /// Failable string-based init — accepts the inputs you'd have from URL query params
    /// or text fields. Returns `nil` when `recipientString` is not a parseable address.
    /// `amount` is best-effort: an unparsable amount becomes `nil` rather than failing.
    public init?(to recipientString: String, amount: String?) {
        guard let recipient = try? Address(string: recipientString) else { return nil }
        self.init(to: recipient, amount: Amount.fromQa(optionalString: amount))
    }

    /// Builds an intent from an array of `URLQueryItem`s, as you would receive from
    /// a deep-link `URLComponents`.
    ///
    /// The recipient (`to`) is required — returns `nil` if it's missing.
    /// The amount is optional and looked up by the same `CodingKeys` name used for JSON,
    /// keeping URL params and JSON shapes in sync.
    public init?(queryParameters params: [URLQueryItem]) {
        guard let addressFromParam = params.first(where: { $0.name == TransactionIntent.CodingKeys.to.stringValue })?
            .value
        else {
            return nil
        }
        let amount = params.first(where: { $0.name == TransactionIntent.CodingKeys.amount.stringValue })?.value
        self.init(to: addressFromParam, amount: amount)
    }

    /// Round-trip representation as URL query items, suitable for embedding in a deep link.
    ///
    /// Sort order is by ascending key length — purely a stable ordering for tests/snapshots
    /// rather than an alphabetical sort, so shorter keys (e.g. `to`) appear before longer
    /// ones (e.g. `amount`).
    public var queryItems: [URLQueryItem] {
        dictionaryRepresentation.compactMap {
            URLQueryItem(name: $0.key, value: String(describing: $0.value).lowercased())
        }.sorted(by: { $0.name.count < $1.name.count })
    }
}

// MARK: - Codable

extension TransactionIntent {
    /// JSON keys for the encoded form. Single source of truth — also used by the
    /// query-parameter init/getter to keep on-wire shapes consistent.
    public enum CodingKeys: CodingKey {
        case to, amount
    }

    /// JSON decoder — both fields go through their own (synthesized for `Amount`,
    /// retroactive for `Address`) `Codable` conformances.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        to = try container.decode(Address.self, forKey: .to)
        amount = try container.decodeIfPresent(Amount.self, forKey: .amount)
    }

    /// JSON encoder — omits `amount` from the output when `nil` (via `encodeIfPresent`).
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(to, forKey: .to)
        try container.encodeIfPresent(amount, forKey: .amount)
    }
}

private extension Amount {
    /// Best-effort parse of a Qa-denominated amount string into an `Amount`.
    /// Returns `nil` for both "no input" and "unparsable input" — callers
    /// here treat both as "no pre-filled amount".
    public static func fromQa(optionalString: String?) -> Amount? {
        guard let qaAmountString = optionalString else { return nil }
        return try? Amount(qa: qaAmountString)
    }
}
