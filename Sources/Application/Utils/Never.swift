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

/// Stub used in `init?(coder:)` overrides — the app does not use Storyboards
/// or XIBs, so these initializers should never be invoked.
var interfaceBuilderSucks: Never {
    fatalError("interfaceBuilderSucks")
}

/// Crashes with a descriptive message. Used at code-paths that indicate a
/// programmer error rather than a user-facing failure (e.g. missing font file,
/// unreachable switch case in an exhaustive enum).
func incorrectImplementation(_ message: CustomStringConvertible) -> Never {
    fatalError("Incorrect implementation - \(message.description)")
}

/// Marker for "abstract" stored properties or methods that subclasses are
/// expected to override. Crashes if invoked on the base class.
var abstract: Never {
    fatalError("Override me")
}
