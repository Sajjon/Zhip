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

import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Capability protocol for the Receive/Scan screens. Injected via Factory so
/// tests can swap a stub that returns canned images / decoded intents.
public protocol QRCoding: AnyObject {
    /// Renders `transaction` as a JSON-encoded QR code at the given pixel size.
    /// Returns `nil` if encoding the JSON or generating the image fails.
    func encode(transaction: TransactionIntent, size: CGFloat) -> UIImage?
    /// Recognizes a QR code in `cgImage` and decodes it back into a `TransactionIntent`.
    /// Returns `nil` if no QR code is found or the payload isn't a valid `TransactionIntent` JSON.
    func decode(cgImage: CGImage) -> TransactionIntent?
}

/// Encodes/decodes `TransactionIntent` to/from QR codes using only Apple-shipped
/// CoreImage APIs (`CIQRCodeGenerator` for encoding, `CIDetector` for decoding).
/// No third-party dependency.
public final class QRCoder {}

extension QRCoder: QRCoding {
    /// Encodes `transaction` to JSON, then runs it through `CIQRCodeGenerator`,
    /// scales the (tiny) generator output up to `size`, and re-tints it to
    /// the brand teal/deep-blue palette so the result looks at home on the
    /// Receive screen. The on-the-wire payload is human-readable JSON so other
    /// Zilliqa clients can interoperate.
    public func encode(transaction: TransactionIntent, size: CGFloat) -> UIImage? {
        guard
            let transactionData = try? JSONEncoder().encode(transaction),
            let content = String(data: transactionData, encoding: .utf8)
        else { return nil }

        return generateImage(content: content, size: size)
    }

    /// Inverse of `encode`. Runs `CIDetector(.qr)` over `cgImage`, takes the
    /// first recognized payload, treats it as UTF-8 JSON, and decodes a
    /// `TransactionIntent`.
    public func decode(cgImage: CGImage) -> TransactionIntent? {
        let ciImage = CIImage(cgImage: cgImage)
        let detector = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: nil,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        )
        let features = detector?.features(in: ciImage) ?? []
        for case let qr as CIQRCodeFeature in features {
            guard
                let scanned = qr.messageString,
                let jsonData = scanned.data(using: .utf8),
                let transaction = try? JSONDecoder().decode(TransactionIntent.self, from: jsonData)
            else { continue }
            return transaction
        }
        return nil
    }
}

// MARK: - Private

private extension QRCoding {
    /// Underlying image generator — always uses our brand teal/deep-blue color
    /// pair so QR codes look at home in the Receive screen.
    func generateImage(
        content: String,
        size cgFloatSize: CGFloat,
        backgroundColor: UIColor = .teal,
        foregroundColor: UIColor = .deepBlue
    ) -> UIImage? {
        guard let payload = content.data(using: .utf8) else { return nil }

        let generator = CIFilter.qrCodeGenerator()
        generator.message = payload
        // Highest error-correction level so the code stays scannable even if the
        // edges are clipped or stained — wallet addresses are useless if the
        // user can't actually scan them.
        generator.correctionLevel = "H"
        guard let coreImage = generator.outputImage else { return nil }

        // CIQRCodeGenerator outputs a tiny ~30×30 px image — scale up to the
        // requested point size with nearest-neighbor scaling so the squares
        // stay crisp (no blurry interpolation).
        let scale = max(1, cgFloatSize / coreImage.extent.width)
        let scaled = coreImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // Tint via CIFalseColor: input color 0 (black squares) → foreground,
        // input color 1 (white background) → background.
        let tint = CIFilter.falseColor()
        tint.inputImage = scaled
        tint.color0 = CIColor(cgColor: foregroundColor.cgColor)
        tint.color1 = CIColor(cgColor: backgroundColor.cgColor)
        guard let tinted = tint.outputImage else { return nil }

        let context = CIContext()
        guard let cgImage = context.createCGImage(tinted, from: tinted.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
