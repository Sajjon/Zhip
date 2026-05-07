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
import UIKit
import XCTest

@MainActor
final class UIButtonExtensionTests: XCTestCase {
    // MARK: - setBackgroundColor(_:for:)

    func test_setBackgroundColor_installsBackgroundImageForState() {
        let sut = UIButton(type: .system)

        sut.setBackgroundColor(.red, for: .normal)

        // Each per-state colour is encoded as a 1×1 background image; verify
        // the image is non-nil after the call.
        XCTAssertNotNil(sut.backgroundImage(for: .normal))
    }

    func test_setBackgroundColor_independentPerState() {
        let sut = UIButton(type: .system)

        sut.setBackgroundColor(.red, for: .normal)
        sut.setBackgroundColor(.blue, for: .disabled)

        XCTAssertNotNil(sut.backgroundImage(for: .normal))
        XCTAssertNotNil(sut.backgroundImage(for: .disabled))
        // Different states get distinct image instances.
        XCTAssertFalse(sut.backgroundImage(for: .normal) === sut.backgroundImage(for: .disabled))
    }

    // MARK: - widthOfTitle(for:)

    func test_widthOfTitle_withFontAndTitleSet_returnsPositiveWidth() {
        let sut = UIButton(type: .system)
        sut.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        sut.setTitle("hello", for: .normal)

        let width = sut.widthOfTitle(for: .normal)

        XCTAssertNotNil(width)
        XCTAssertGreaterThan(width ?? 0, 0)
    }

    func test_widthOfTitle_withNoTitleAtAll_returnsNil() {
        let sut = UIButton(type: .system)
        sut.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        // Deliberately leave the title unset for every state — UIButton's
        // `title(for:)` fallback chains states, so the only way to reliably
        // return nil from `widthOfTitle` is to never set a title at all.

        XCTAssertNil(sut.widthOfTitle(for: .normal))
    }

    func test_widthOfTitle_defaultsToNormalState() {
        let sut = UIButton(type: .system)
        sut.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        sut.setTitle("hello", for: .normal)

        // Calling without an explicit state should return the .normal width.
        XCTAssertEqual(sut.widthOfTitle(), sut.widthOfTitle(for: .normal))
    }
}
