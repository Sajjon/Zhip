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

/// Runs `make` synchronously on the calling thread, asserting that thread is
/// the main thread *first* and then telling the compiler to treat the body
/// as `@MainActor`-isolated.
///
/// **Why this wrapper exists:**
///
/// Many Zhip integration points (Factory `register` closures, Combine `sink`
/// closures) are typed `@Sendable` by the framework — they could in principle
/// be invoked off the main thread. But every concrete usage in this app
/// resolves on the main thread (Factory singletons are first-touched from
/// `bootstrap()` / coordinators, and the Combine pipelines we sink from are
/// already `.receive(on: RunLoop.main)`). The MainActor-isolated init or
/// method we want to call inside the closure is therefore *actually* safe.
///
/// `MainActor.assumeIsolated { … }` is the Swift-blessed escape hatch for
/// this case — but on its own it traps deep inside Swift Concurrency runtime
/// if the assumption is wrong, with an error message that doesn't name the
/// call site. This wrapper adds a `precondition(Thread.isMainThread)` first,
/// so a regression (e.g. Factory v3 changing resolver semantics to background
/// resolution) fails loudly *at the call site* instead of inside libdispatch.
///
/// In production builds `precondition` is still active (only `assert` is
/// stripped), so the safety check has zero compile-time cost and a single
/// branch at runtime.
///
/// ## Example
///
/// ```swift
/// // BEFORE — silent on regression:
/// var pasteboard: Factory<Pasteboard> {
///     self { MainActor.assumeIsolated { DefaultPasteboard() } }.singleton
/// }
///
/// // AFTER — fails loudly at the call site if Factory ever resolves off-main:
/// var pasteboard: Factory<Pasteboard> {
///     self { mainActorOnly { DefaultPasteboard() } }.singleton
/// }
/// ```
@inlinable
func mainActorOnly<T: Sendable>(
    _ make: @MainActor () -> T,
    file: StaticString = #fileID,
    line: UInt = #line
) -> T {
    precondition(
        Thread.isMainThread,
        "mainActorOnly { … } invoked off the main thread — this is the call site that needs to be hopped via MainActor.run / DispatchQueue.main.async first.",
        file: file,
        line: line
    )
    return MainActor.assumeIsolated { make() }
}
