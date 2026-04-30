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

/// Check if active Config is `Debug`
///
/// Cheaper than `#if DEBUG` because it can be referenced from non-conditionally
/// compiled code paths and read at runtime. The trick: `assert` is only
/// evaluated in `-Onone` (Debug) builds, so the side-effect inside it never
/// fires under Release optimization — meaning `isDebug` stays `false`.
/// https://stackoverflow.com/a/47443568/1311272
public let isDebug: Bool = {
    var isDebug = false
    /// function with a side effect and Bool return value that we can pass into assert()
    func set(debug: Bool) -> Bool {
        isDebug = debug
        return isDebug
    }
    // assert:
    // "Condition is only evaluated in playgrounds and -Onone builds."
    // so isDebug is never changed to true in Release builds
    assert(set(debug: true))
    return isDebug
}()
