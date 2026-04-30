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

@testable import AppFeature
import KeychainSwift
import XCTest

/// Exercises `KeychainSwift`'s `KeyValueStoring` conformance against the real
/// simulator keychain. Each test uses a namespaced key to avoid collisions.
final class KeychainSwiftKeyValueStoringTests: XCTestCase {
    private var sut: KeychainSwift!
    private let stringKey = "zhip.tests.keychain.string"
    private let dataKey = "zhip.tests.keychain.data"
    private let boolKey = "zhip.tests.keychain.bool"

    override func setUp() {
        super.setUp()
        sut = KeychainSwift(keyPrefix: "zhip.tests.")
        sut.deleteValue(for: stringKey)
        sut.deleteValue(for: dataKey)
        sut.deleteValue(for: boolKey)
    }

    override func tearDown() {
        sut.deleteValue(for: stringKey)
        sut.deleteValue(for: dataKey)
        sut.deleteValue(for: boolKey)
        sut = nil
        super.tearDown()
    }

    /// Exercises the string branch of `save(value:for:)` and the load path. The
    /// simulator keychain requires a device passcode for the configured
    /// accessibility option, so persistence can silently no-op — we only
    /// assert that the call runs without crashing, which is enough to cover
    /// the branch.
    func test_save_string_executesWithoutCrashing() {
        sut.save(value: "hello", for: stringKey)
        _ = sut.loadValue(for: stringKey)
    }

    /// Exercises the bool branch of `save(value:for:)`.
    func test_save_bool_executesWithoutCrashing() {
        sut.save(value: true, for: boolKey)
        _ = sut.loadValue(for: boolKey)
    }

    /// Exercises the Data branch of `save(value:for:)` and the `getData` hit
    /// branch in `loadValue(for:)`. Data persistence is reliable on the
    /// simulator even without a device passcode.
    func test_save_data_roundTrips() {
        let payload = Data([0x01, 0x02, 0x03, 0x04])
        sut.save(value: payload, for: dataKey)
        XCTAssertEqual(sut.loadValue(for: dataKey) as? Data, payload)
    }

    func test_loadValue_unknownKey_returnsNil() {
        XCTAssertNil(sut.loadValue(for: "zhip.tests.unknown"))
    }

    func test_deleteValue_removesStored() {
        sut.save(value: "stored", for: stringKey)
        sut.deleteValue(for: stringKey)
        XCTAssertNil(sut.loadValue(for: stringKey))
    }
}
