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

/// Conforming styles can be combined with another instance of themselves.
///
/// Used throughout the styling system: a base style (`.body`) is merged with
/// per-call overrides (`{ $0.color(.red) }`) so call sites can declaratively
/// tweak only the attributes they care about, with the rest inherited.
public protocol Mergeable {
    /// Merges `self` with `other` according to `mode`, returning a new instance.
    /// Conformers decide on a field-by-field basis using `mergeAttribute(...)`.
    func merged(other: Self, mode: MergeMode) -> Self
}

extension Mergeable {
    /// Merge with an optional `other`, preferring `other`'s non-nil fields.
    /// `nil` other → unchanged self.
    func merge(yieldingTo other: Self?) -> Self {
        guard let other else { return self }
        return merge(yieldingTo: other)
    }

    /// Merge with `other`, preferring `other`'s non-nil fields where both
    /// sides have a value (the "yield to override" pattern used when a base
    /// style is being overridden by a more specific one).
    func merge(yieldingTo other: Self) -> Self {
        merged(other: other, mode: .yieldToOther)
    }

    /// Merge with an optional `other`, preferring `self`'s non-nil fields.
    /// `nil` other → unchanged self.
    func merge(overridingOther other: Self?) -> Self {
        guard let other else { return self }
        return merge(overridingOther: other)
    }

    /// Merge with `other`, preferring `self`'s non-nil fields. Used when the
    /// receiver is the override and `other` is the fallback.
    func merge(overridingOther other: Self) -> Self {
        merged(other: other, mode: .overrideOther)
    }
}

public extension Mergeable {
    /// Per-attribute merge helper used inside concrete `merged(other:mode:)`
    /// implementations. Picks the right value based on `mode` and the
    /// nil-ness of each side, so call sites are one line per field.
    func mergeAttribute<T>(other: Self, path attributePath: KeyPath<Self, T?>, mode: MergeMode) -> T? {
        let selfAttribute = self[keyPath: attributePath]
        let otherAttribute = other[keyPath: attributePath]
        switch mode {
        case .overrideOther: return selfAttribute ?? otherAttribute
        case .yieldToOther: return otherAttribute ?? selfAttribute
        }
    }
}

/// Direction of a merge operation — selects which side's non-nil attributes win.
public enum MergeMode {
    /// `self`'s non-nil attributes take precedence; falls back to `other` only
    /// for fields `self` left nil.
    case overrideOther
    /// `other`'s non-nil attributes take precedence; falls back to `self` only
    /// for fields `other` left nil.
    case yieldToOther
}

extension Optional where Wrapped: Mergeable {
    /// Optional-friendly merge: if `self` is nil, just return `other` whole;
    /// otherwise merge with `self`'s fields taking precedence.
    func merge(overridingOther other: Wrapped) -> Wrapped {
        merged(other: other, mode: .overrideOther)
    }

    /// Optional-friendly merge: if `self` is nil, return `other` whole;
    /// otherwise merge with `other`'s fields taking precedence.
    func merge(yieldingTo other: Wrapped) -> Wrapped {
        merged(other: other, mode: .yieldToOther)
    }

    /// Internal worker shared by both `Optional` merge variants — handles the
    /// "self is nil" short-circuit before delegating.
    private func merged(other: Wrapped, mode: MergeMode) -> Wrapped {
        guard let self else { return other }
        return `self`.merged(other: other, mode: mode)
    }
}
