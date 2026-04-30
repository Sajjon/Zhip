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

import Combine
import UIKit
import SingleLineControllerNavigation

/// App-level dispatcher that turns inbound universal-link URLs into typed
/// `DeepLink` events on `navigation`.
///
/// Buffers a single deep link while the app is locked behind PIN, then replays
/// it once `appIsUnlockedEmitBufferedDeeplinks()` is called from the unlock flow.
public final class DeepLinkHandler {
    /// Stepper that surfaces parsed deep links.
    private let navigator: Navigator<DeepLink>

    /// This buffered link gets set when the app is locked with a PIN code
    private var bufferedLink: DeepLink?
    /// While `true`, incoming links are stashed in `bufferedLink` and the
    /// `navigation` publisher filters out any pulses.
    private var appIsLockedSoBufferLink = false

    /// Injects the navigator (default: a fresh one). Tests can pass a custom
    /// navigator to assert ordering of events.
    init(navigator: Navigator<DeepLink> = Navigator<DeepLink>()) {
        self.navigator = navigator
    }

    /// Called by the app-lock coordinator when the PIN screen appears.
    /// Subsequent deep links will be buffered until unlock.
    func appIsLockedBufferDeeplinks() {
        appIsLockedSoBufferLink = true
    }

    /// Called by the unlock coordinator after a successful PIN. Replays the
    /// most recently buffered link (if any) and clears the buffer.
    func appIsUnlockedEmitBufferedDeeplinks() {
        defer { bufferedLink = nil }
        appIsLockedSoBufferLink = false
        guard let link = bufferedLink else { return }
        navigate(to: link)
    }
}

extension DeepLinkHandler {
    /// Read more: https://developer.apple.com/documentation/uikit/core_app/allowing_apps_and_websites_to_link_to_your_content/handling_universal_links
    /// Handles universal link `url`, e.g. `https://zhip.app/send?to=0x1a2b3c&amount=1337`
    ///
    /// return: `true` if the delegate successfully handled the request or `false` if the attempt to open the URL
    /// resource failed.
    func handle(url: URL) -> Bool {
        guard let destination = DeepLink(url: url) else {
            return false
        }

        navigate(to: destination)
        return true
    }

    /// Public stream of deep links, gated by the lock flag so subscribers
    /// don't see anything while the app is locked. The underlying navigator
    /// is *also* never advanced while locked (see `navigate(to:)` below) —
    /// the filter is belt-and-suspenders.
    var navigation: AnyPublisher<DeepLink, Never> {
        navigator.navigation.filter { [weak self] _ in !(self?.appIsLockedSoBufferLink ?? true) }
            .eraseToAnyPublisher()
    }
}

// MARK: Private

private extension DeepLinkHandler {
    /// Either buffers `destination` (locked) or pushes it through the navigator (unlocked).
    func navigate(to destination: DeepLink) {
        if appIsLockedSoBufferLink {
            bufferedLink = destination
        } else {
            navigator.next(destination)
        }
    }
}
