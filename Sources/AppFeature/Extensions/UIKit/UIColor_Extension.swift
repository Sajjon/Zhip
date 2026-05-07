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

import UIKit

public extension UIColor {
    /// Default foreground colour for body text — white, to fit the dark theme.
    static var defaultText: UIColor {
        .white
    }
}

extension UIColor {
    /// The closed set of brand colours used by the app, encoded as raw RGB hex
    /// integers. Centralised here so palette changes happen in one place and
    /// the rest of the app references named cases (`.teal`, `.deepBlue`, …).
    enum Hex: Int {
        /// Brand primary — teal accent for buttons, links, focus rings.
        case teal = 0x00A88D

        /// Pressed/disabled variant of `.teal`.
        case darkTeal = 0x0F675B
        /// Warning highlight (e.g. validation hints, special callouts).
        case mellowYellow = 0xFFD14C
        /// App-wide background colour.
        case deepBlue = 0x1F292F
        /// Error / destructive accent.
        case bloodRed = 0xFF4C4F
        /// Secondary surface (cards, sections).
        case asphaltGrey = 0x40484D
        /// Disabled / placeholder text colour.
        case silverGrey = 0x6F7579

        /// Dark color used for navigation bar
        case dusk = 0x192226
    }
}

extension UIColor {
    /// Returns this colour's RGB components rendered as a `#rrggbb` hex string.
    /// Alpha is intentionally not encoded — the use sites here are colour
    /// previews and debug logs where the alpha rarely matters.
    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let rgb = Int(red * 255) << 16 | Int(green * 255) << 8 | Int(blue * 255) << 0

        return String(format: "#%06x", rgb)
    }
}

public extension UIColor {
    /// Brand teal — primary accent.
    static let teal = UIColor(hex: .teal)
    /// Brand teal pressed/disabled state.
    static let darkTeal = UIColor(hex: .darkTeal)
    /// App-wide background.
    static let deepBlue = UIColor(hex: .deepBlue)
    /// Mellow yellow — warning accent.
    static let mellowYellow = UIColor(hex: .mellowYellow)
    /// Blood red — error/destructive accent.
    static let bloodRed = UIColor(hex: .bloodRed)
    /// Asphalt grey — secondary surface.
    static let asphaltGrey = UIColor(hex: .asphaltGrey)
    /// Silver grey — disabled / placeholder text.
    static let silverGrey = UIColor(hex: .silverGrey)
    /// Dusk — navigation bar.
    static let dusk = UIColor(hex: .dusk)
}

// MARK: - Private

private extension UIColor {
    /// Decodes a brand `Hex` value into a `UIColor`. Splits the 24-bit integer
    /// into 8-bit channels via right-shift + mask, then normalises each channel
    /// to `0…1`. Made private so the rest of the codebase only sees the named
    /// `static let` colours above.
    convenience init(hex: Hex, alpha: CGFloat = 1.0) {
        let hexInt: Int = hex.rawValue
        let components = (
            R: CGFloat((hexInt >> 16) & 0xFF) / 255,
            G: CGFloat((hexInt >> 08) & 0xFF) / 255,
            B: CGFloat((hexInt >> 00) & 0xFF) / 255
        )
        self.init(red: components.R, green: components.G, blue: components.B, alpha: alpha)
    }
}
