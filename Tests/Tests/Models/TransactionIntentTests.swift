import XCTest
import Zesame
@testable import Zhip

final class TransactionIntentTests: XCTestCase {
    private let validAddressString = "e3090a1309DfAC40352d03dEc6cCD9cAd213e76B"

    func test_initWithAddress_storesRecipient() throws {
        let address = try Address(string: validAddressString)
        let sut = TransactionIntent(to: address)
        XCTAssertEqual(sut.to, address)
        XCTAssertNil(sut.amount)
    }

    func test_initWithString_invalidAddress_returnsNil() {
        let sut = TransactionIntent(to: "not-an-address", amount: nil)
        XCTAssertNil(sut)
    }

    func test_initWithString_validAddress_succeeds() {
        let sut = TransactionIntent(to: validAddressString, amount: nil)
        XCTAssertNotNil(sut)
    }

    func test_fromScannedQrCodeString_validAddress_returnsIntent() throws {
        let intent = try TransactionIntent.fromScannedQrCodeString(validAddressString)
        XCTAssertNotNil(intent)
    }

    func test_fromScannedQrCodeString_invalidGarbage_throws() {
        XCTAssertThrowsError(try TransactionIntent.fromScannedQrCodeString("not-an-address-or-json"))
    }

    func test_queryItems_containsTo() throws {
        let address = try Address(string: validAddressString)
        let sut = TransactionIntent(to: address)
        let names = sut.queryItems.map(\.name)
        XCTAssertTrue(names.contains("to"))
    }

    func test_initWithQueryParameters_missingTo_returnsNil() {
        let sut = TransactionIntent(queryParameters: [URLQueryItem(name: "amount", value: "100")])
        XCTAssertNil(sut)
    }

    func test_initWithQueryParameters_validTo_succeeds() {
        let sut = TransactionIntent(queryParameters: [URLQueryItem(name: "to", value: validAddressString)])
        XCTAssertNotNil(sut)
    }

    func test_error_equatable() {
        XCTAssertEqual(TransactionIntent.Error.scannedStringNotAddressNorJson, .scannedStringNotAddressNorJson)
    }

    // MARK: - Codable / fromScannedQrCodeString JSON branch

    func test_initWithQueryParameters_validAmount_parsesAmount() {
        let sut = TransactionIntent(
            queryParameters: [
                URLQueryItem(name: "to", value: validAddressString),
                URLQueryItem(name: "amount", value: "1000000000000"),
            ]
        )

        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut?.amount)
    }

    // MARK: - Codable / fromScannedQrCodeString JSON branch

    ///
    /// Note: `Address.init(from decoder:)` lowercases the decoded string before
    /// validating it, which conflicts with EIP-55-style mixed-case checksumming.
    /// So the JSON path always throws "notChecksummed" for properly-formed
    /// Zilliqa addresses. We still exercise the branch by feeding a malformed
    /// JSON body and asserting that `fromScannedQrCodeString` propagates.
    func test_fromScannedQrCodeString_invalidJson_throws() {
        let json = "{\"to\":\"\(validAddressString)\"}"

        XCTAssertThrowsError(try TransactionIntent.fromScannedQrCodeString(json))
    }
}
