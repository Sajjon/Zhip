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
import UIKit
import XCTest
import Zesame

/// Exercises `QRCoder`'s encode and decode paths. Decoding a blank image
/// returns nil (no QR content); encoding a valid `TransactionIntent` returns
/// an image.
@MainActor
final class QRCodingTests: XCTestCase {
    private var sut: QRCoder!

    override func setUp() {
        super.setUp()
        sut = QRCoder()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    private func makeBlankCGImage() -> CGImage {
        let size = CGSize(width: 32, height: 32)
        UIGraphicsBeginImageContext(size)
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!.cgImage!
    }

    func test_decode_blankImage_returnsNil() {
        let intent = sut.decode(cgImage: makeBlankCGImage())

        XCTAssertNil(intent)
    }

    func test_encode_transaction_returnsImage() throws {
        let address = try Address(string: "e3090a1309DfAC40352d03dEc6cCD9cAd213e76B")
        let intent = TransactionIntent(to: address)

        let image = sut.encode(transaction: intent, size: 200)

        XCTAssertNotNil(image)
    }
}
