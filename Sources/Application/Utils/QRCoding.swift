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

import EFQRCode
import UIKit

/// Capability protocol for the Receive/Scan screens. Injected via Factory so
/// tests can swap a stub that returns canned images / decoded intents.
protocol QRCoding: AnyObject {
    /// Renders `transaction` as a JSON-encoded QR code at the given pixel size.
    /// Returns `nil` if encoding the JSON or generating the image fails.
    func encode(transaction: TransactionIntent, size: CGFloat) -> UIImage?
    /// Recognizes a QR code in `cgImage` and decodes it back into a `TransactionIntent`.
    /// Returns `nil` if no QR code is found or the payload isn't a valid `TransactionIntent` JSON.
    func decode(cgImage: CGImage) -> TransactionIntent?
}

/// A type capable of encoding and decoding Transaction to and from QR codes
final class QRCoder {}

extension QRCoder: QRCoding {
    /// Encodes `transaction` to JSON, then runs it through `EFQRCode.generate`
    /// at the requested size. The on-the-wire payload is human-readable JSON so
    /// other Zilliqa clients can interoperate.
    func encode(transaction: TransactionIntent, size: CGFloat) -> UIImage? {
        guard
            let transactionData = try? JSONEncoder().encode(transaction),
            let content = String(data: transactionData, encoding: .utf8)
        else { return nil }

        return generateImage(content: content, size: size)
    }

    /// Inverse of `encode`. Pulls the first recognized QR string out of the
    /// `cgImage`, treats it as UTF-8 JSON, and decodes a `TransactionIntent`.
    func decode(cgImage: CGImage) -> TransactionIntent? {
        let scannedContentStrings = EFQRCode.recognize(cgImage)
        guard
            let scannedContentString = scannedContentStrings.first,
            let jsonData = scannedContentString.data(using: .utf8),
            let transaction = try? JSONDecoder().decode(TransactionIntent.self, from: jsonData)
        else { return nil }
        return transaction
    }
}

// MARK: - Private

private extension QRCoding {
    /// Underlying image generator — always uses our brand teal/deep-blue color
    /// pair so QR codes look at home in the Receive screen. The watermark
    /// parameter is reserved for future use (we may stamp a Zilliqa logo).
    func generateImage(
        content: String,
        size cgFloatSize: CGFloat,
        backgroundColor: UIColor = .teal,
        foregroundColor: UIColor = .deepBlue,
        watermarkImage: UIImage? = nil
    ) -> UIImage? {
        let intSize = Int(cgFloatSize)
        let size = EFIntSize(width: intSize, height: intSize)

        guard let cgImage = EFQRCode.generate(
            for: content,
            size: size,
            backgroundColor: backgroundColor.cgColor,
            foregroundColor: foregroundColor.cgColor,
            watermark: watermarkImage?.cgImage
        ) else { return nil }

        return UIImage(cgImage: cgImage)
    }
}
