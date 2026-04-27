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
import SingleLineControllerCore

/// Builds outgoing `zhip.app` HTTPS URLs that, when opened, re-enter the app via
/// the deep-link handler. Exists behind a protocol so coordinators depend on the
/// abstraction and tests can stub URL construction deterministically.
protocol DeepLinkGenerator: AnyObject {

    /// Builds a sharable URL that, when opened, navigates the recipient to the
    /// "send" flow pre-populated with the fields of `transaction`.
    func linkTo(transaction: TransactionIntent) -> URL
}

/// Default URL-components–based builder used in production.
final class DefaultDeepLinkGenerator: DeepLinkGenerator {

    /// Trivial init — no dependencies.
    init() {}

    /// Builds `https://zhip.app/send?…` from `transaction.queryItems`.
    /// Crashes (`incorrectImplementation`) if URL composition fails — at this
    /// point we have a known scheme/host/path, so a `nil` indicates a logic bug.
    func linkTo(transaction: TransactionIntent) -> URL {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "zhip.app"
        urlComponents.path = DeepLink.Path.send.rawValue
        urlComponents.queryItems = transaction.queryItems
        guard let shareUrl = urlComponents.url else {
            incorrectImplementation(
                "Should be possible to create share link for transaction: \(transaction), check implementation, urlComponents: `\(urlComponents.debugDescription)`"
            )
        }
        return shareUrl
    }
}

