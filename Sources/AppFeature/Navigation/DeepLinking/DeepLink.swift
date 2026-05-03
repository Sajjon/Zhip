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

/// In-app representation of a parsed universal-link URL.
///
/// New deep-link types should be added as new cases here, with a matching entry
/// in `DeepLink.Path` and parsing logic in the URL initializer below.
public enum DeepLink: Sendable {
    /// `https://zhip.app/send?to=...&amount=...` — pre-fills the Send screen.
    case send(TransactionIntent)
}

extension DeepLink {
    /// Convenience accessor for the `.send` payload — `nil` for any other case.
    var asTransaction: TransactionIntent? {
        switch self {
        case let .send(transaction): transaction
        }
    }
}

extension DeepLink {
    /// URL-path mapping for each deep link case. The raw value is the path
    /// component (with leading slash) we expect in the incoming URL.
    enum Path: String {
        case send = "/send"
    }
}

extension DeepLink {
    /// Errors emitted by the deep-link parser. Currently parsing failures fall
    /// through to a `nil` initializer return, but the type exists for clients
    /// that want to surface a typed error.
    enum ParseError: Swift.Error {
        case failedToParse
    }

    /// Parses `url` into a `DeepLink`, or returns `nil` if the URL doesn't
    /// match any known path or its query parameters can't be decoded.
    init?(url: URL) {
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let params = components.queryItems
        else {
            return nil
        }

        // Reject any path we don't have a case for — keeps the parser future-proof.
        guard let deepLinkPath = DeepLink.Path(rawValue: components.path) else {
            return nil
        }

        switch deepLinkPath {
        case .send:
            if let transaction = TransactionIntent(queryParameters: params) {
                self = .send(transaction)
            } else {
                return nil
            }
        }
    }
}
