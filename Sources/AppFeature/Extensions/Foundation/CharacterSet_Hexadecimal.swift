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
import Zesame

extension CharacterSet {
    /// Hex digits (`0-9`, `a-f`, `A-F`) plus the literal `0x` prefix characters.
    /// Used to validate user-pasted hex addresses / private keys where the prefix
    /// is optional.
    static var hexadecimalDigitsIncluding0x: CharacterSet {
        let afToAF = CharacterSet(charactersIn: "abcdefABCDEF")
        return CharacterSet.decimalDigits
            .union(afToAF)
            .union(CharacterSet(charactersIn: "0x"))
    }

    /// Bech32 alphabet (both cases) plus the network's Bech32 prefix character(s).
    /// Used to validate `zil1…` / `tzil1…` style addresses pasted by the user.
    static var bech32IncludingPrefix: CharacterSet {
        let lowercase = Zesame.Bech32.alphabetString.lowercased()
        let uppercase = Zesame.Bech32.alphabetString.uppercased()

        return CharacterSet(charactersIn: lowercase)
            .union(CharacterSet(charactersIn: uppercase))
            .union(CharacterSet(charactersIn: network.bech32Prefix))
    }

    /// Permissive set accepting *either* a Bech32 address *or* a hex-style address —
    /// the address-input field accepts both representations interchangeably.
    static var bech32OrHexIncludingPrefix: CharacterSet {
        CharacterSet.bech32IncludingPrefix.union(hexadecimalDigitsIncluding0x)
    }

    /// Digits plus the user's locale-specific decimal separator and both the
    /// dot and comma fallback. Used to validate amount inputs in a way that
    /// accommodates `1,5` (DE/SE/...) and `1.5` (US/UK) without forcing the user
    /// to switch keyboard.
    static var decimalWithSeparator: CharacterSet {
        CharacterSet.decimalDigits
            .union(CharacterSet(charactersIn: Locale.current.decimalSeparatorForSure))
            .union(CharacterSet(charactersIn: "."))
            .union(CharacterSet(charactersIn: ","))
    }
}
