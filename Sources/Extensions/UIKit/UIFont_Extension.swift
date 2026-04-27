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
import UIKit
import SingleLineControllerCore

// The app uses Barlow at a small set of fixed sizes/weights. The named tokens
// below (e.g. `.body`, `.header`, `.callToAction`) are the *only* fonts call
// sites should reference — adding a one-off `UIFont(name:size:)` somewhere is
// a smell. To add a new typography role, add a token here.

extension UIFont {
    /// 16pt Barlow Medium — `UITextField` floating placeholder.
    static let hint = Font(.𝟙𝟞, .medium).make()
    /// 16pt Barlow Regular — small caption text above a value.
    static let valueTitle = Font(.𝟙𝟞, .regular).make()
    /// 18pt Barlow Bold — primary value text (numbers, addresses).
    static let value = Font(.𝟙𝟠, .bold).make()

    /// For bread text
    static let body = Font(.𝟙𝟠, .regular).make()

    /// `UIViewController`'s `title`, checkboxes, `UIBarButtonItem`, `UITextField`'s placeholder & value
    static let title = Font(.𝟙𝟠, .semiBold).make()

    /// UIButton
    static let callToAction = Font(.𝟚𝟘, .semiBold).make()

    /// First label in a scene
    static let header = Font(.𝟛𝟜, .bold).make()

    /// Welcome, ChoseWallet scene
    static let impression = Font(.𝟜𝟠, .bold).make()

    /// 86pt Barlow SemiBold — splash/hero "BIG BANG" text.
    static let bigBang = Font(.𝟠𝟞, .semiBold).make()
}

// Semantic aliases — same underlying fonts, but with names that read at the
// call site. `someLabel.font = .sceneTitle` is clearer than `.title` when the
// label *is* a scene title.
extension UIFont {
    /// Alias of `.title` used by navigation/scene title labels.
    static let sceneTitle: UIFont = .title
    /// Alias of `.title` used by checkbox labels.
    static let checkbox: UIFont = .title
    /// Alias of `.title` used by `UIBarButtonItem` text.
    static let barButtonItem: UIFont = .title
    /// Alias of `.callToAction` used by primary `UIButton`s.
    static let button: UIFont = .callToAction

    /// Namespace grouping the fonts intended for label use.
    enum Label {
        /// Hero/welcome label font.
        static let impression: UIFont = .impression
        /// Scene-header label font.
        static let header: UIFont = .header
        /// Body-text label font.
        static let body: UIFont = .body
    }

    /// Namespace grouping the fonts intended for input-field use.
    enum Field {
        /// Floating-label placeholder font.
        static let floatingPlaceholder: UIFont = .hint
        /// Main text + non-floating placeholder font.
        static let textAndPlaceholder: UIFont = .title
    }
}

/// The four Barlow weights used in the app, mapped to their PostScript names.
/// `FontNameExpressible` provides `name` automatically via the raw value.
enum FontBarlow: String, FontNameExpressible {
    case regular = "Barlow-Regular"
    case medium = "Barlow-Medium"
    case bold = "Barlow-Bold"
    case semiBold = "Barlow-SemiBold"
}

/// Builder pairing a typographic size with a Barlow weight; call `.make()`
/// to get the resolved `UIFont`. Lets the named tokens above stay one-liners.
struct Font {
    /// The size token (must come from `Font.FontSize`).
    let size: FontSize
    /// PostScript name of the Barlow weight; resolved from `FontBarlow.name`.
    fileprivate let name: String
    /// Designated initialiser: pick a size and a weight.
    init(_ size: FontSize, _ barlow: FontBarlow) {
        self.size = size
        name = barlow.name
    }
}

// swiftlint:disable identifier_name
extension Font {
    /// The closed set of sizes the design system uses. The unicode "double-struck"
    /// digits in the case names are intentional — they make the size jump out
    /// visually at the use site (`Font(.𝟚𝟘, .semiBold)` reads as "20"-something).
    enum FontSize: CGFloat {
        // 𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡

        /// 16pt — small text (placeholders, captions).
        case 𝟙𝟞 = 16
        /// 18pt — body / value / scene title.
        case 𝟙𝟠 = 18
        /// 20pt — call-to-action buttons.
        case 𝟚𝟘 = 20

        /// 34pt — header label.
        case 𝟛𝟜 = 34

        /// 48pt — impression/welcome.
        case 𝟜𝟠 = 48
        /// 86pt — splash hero.
        case 𝟠𝟞 = 86
    }
}

// swiftlint:enable identifier_name

/// Protocol providing the PostScript name of a font. Lets enums or other types
/// describe their underlying font without each one re-implementing the same
/// `name: String` accessor.
protocol FontNameExpressible {
    /// PostScript name of the font, as `UIFont(name:size:)` expects.
    var name: String { get }
}

extension FontNameExpressible where Self: RawRepresentable, Self.RawValue == String {
    /// Default — the raw string value *is* the PostScript name.
    /// Lets `enum FontBarlow: String` get `name` for free.
    var name: String {
        rawValue
    }
}

extension Font {
    /// Resolves this `Font` to an actual `UIFont` instance via UIKit's font registry.
    /// Crashes loudly if the named font isn't registered with UIKit — typically
    /// indicates a missing entry in `UIAppFonts` or a renamed asset.
    func make() -> UIFont {
        guard let customFont = UIFont(name: name, size: size.rawValue) else {
            incorrectImplementation("Failed to load custom font named: '\(name)'")
        }
        return customFont
    }
}

