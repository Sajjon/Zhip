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

@testable import AppFeature
import Resources
import WebKit
import XCTest

@MainActor
final class WKWebViewExtensionsTests: XCTestCase {
    func test_convenienceInit_withDefaultConfiguration_disablesAutoresizingMask() {
        // Pass an explicit config to disambiguate from the iOS 26 SDK's
        // own no-arg `WKWebView()` initialiser, ensuring our convenience
        // init runs (and therefore `translatesAutoresizingMaskIntoConstraints`
        // gets disabled).
        let sut = WKWebView(configuration: WKWebViewConfiguration())

        XCTAssertFalse(sut.translatesAutoresizingMaskIntoConstraints)
    }

    func test_convenienceInit_acceptsCustomConfiguration() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        let sut = WKWebView(configuration: configuration)

        XCTAssertTrue(sut.configuration.allowsInlineMediaPlayback)
        XCTAssertFalse(sut.translatesAutoresizingMaskIntoConstraints)
    }

    func test_loadHtml_withBundledResource_doesNotCrash() throws {
        // The Resources module ships a `TermsOfService.html` file —
        // `loadHtml` should locate it via the bundle, read it, and call
        // `loadHTMLString`. We don't assert on the rendered DOM (WKWebView
        // load is async and out of scope for a unit test); just that the
        // call returns without `incorrectImplementation`-trapping.
        let sut = WKWebView()

        sut.loadHtml(file: "TermsOfService", in: Resources.bundle)

        // If we reach this line, the resource was found and parsed.
        XCTAssertTrue(true)
    }
}
