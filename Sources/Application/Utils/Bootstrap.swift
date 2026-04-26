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

import CoreText
import FirebaseAnalytics
import FirebaseCore
import Foundation
import IQKeyboardManagerSwift
import SwiftyBeaver
import Zesame

/// The global logger used throughout the app.
let log = SwiftyBeaver.self

/// One-time app initialization run from the `AppDelegate`.
///
/// Order matters:
/// 1. `registerFonts` so `UINavigationBar.appearance()` can reference our font.
/// 2. `setupAppearance` so every view created later inherits the right styling.
/// 3. `setupKeyboardHiding` (IQKeyboardManager).
/// 4. `setupCrashReportingIfAllowed` — gated on the user's `hasAcceptedCrashReporting` preference.
/// 5. `setupLogging` — debug-only console destination.
func bootstrap() {
    registerFonts()
    AppAppearance.setupDefault()
    setupKeyboardHiding()
    setupCrashReportingIfAllowed()
    setupLogging()
}

/// Registers every `Barlow-*.ttf` font shipped in the bundle with CoreText so
/// they're available to `UIFont(name:size:)`. Falls into `incorrectImplementation`
/// (a `Never`-returning fatal) if a file is missing — we'd rather crash at
/// launch than render blank text in production.
private func registerFonts() {
    let fontFileNames = [
        "Barlow-Black", "Barlow-BlackItalic",
        "Barlow-Bold", "Barlow-BoldItalic",
        "Barlow-ExtraBold", "Barlow-ExtraBoldItalic",
        "Barlow-ExtraLight", "Barlow-ExtraLightItalic",
        "Barlow-Italic",
        "Barlow-Light", "Barlow-LightItalic",
        "Barlow-Medium", "Barlow-MediumItalic",
        "Barlow-Regular",
        "Barlow-SemiBold", "Barlow-SemiBoldItalic",
        "Barlow-Thin", "Barlow-ThinItalic",
    ]
    for name in fontFileNames {
        guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
            incorrectImplementation("Missing font file: \(name).ttf")
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}

/// Toggles Firebase Analytics + crash reporting based on the user's
/// `hasAcceptedCrashReporting` preference.
///
/// Called both at launch and after the user toggles the preference in Settings,
/// so the function is idempotent — it tears down `FirebaseApp` when disabled
/// and refuses to re-initialize when already configured.
func setupCrashReportingIfAllowed() {
    guard Preferences.default.isTrue(.hasAcceptedCrashReporting) else {
        Analytics.setAnalyticsCollectionEnabled(false)
        FirebaseApp.app()?.delete { _ in
            /* required completion handler */
        }
        return
    }
    guard FirebaseApp.app() == nil else {
        // already configured, crash if called twice
        return
    }
    // FirebaseConfiguration.shared.setLoggerLevel was removed in Firebase 9+.
    // Logging verbosity is now controlled via the FIREBASE_LOG_LEVEL environment variable.
    FirebaseApp.configure()
    Analytics.setAnalyticsCollectionEnabled(true)
}

/// Enables `IQKeyboardManager` so taps outside text fields dismiss the keyboard
/// without per-screen `endEditing(_:)` plumbing.
private func setupKeyboardHiding() {
    IQKeyboardManager.shared.enable = true
}

/// Adds a verbose console destination to SwiftyBeaver — Debug builds only.
/// Release builds ship without any log output.
private func setupLogging() {
    // only allow logging for Debug builds
    guard isDebug else { return }
    let console = ConsoleDestination()
    console.minLevel = .verbose
    log.addDestination(console)
}
