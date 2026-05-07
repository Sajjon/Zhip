@testable import AppFeature
import XCTest
import Zesame

@MainActor
final class DeepLinkGeneratorTests: XCTestCase {
    func test_linkTo_transaction_usesHttpsAndZhipHostAndSendPath() throws {
        let address = try Address(string: "e3090a1309DfAC40352d03dEc6cCD9cAd213e76B")
        let intent = TransactionIntent(to: address)

        let url = DefaultDeepLinkGenerator().linkTo(transaction: intent)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        XCTAssertEqual(components?.scheme, "https")
        XCTAssertEqual(components?.host, "zhip.app")
        XCTAssertEqual(components?.path, "/send")
    }

    func test_linkTo_transaction_includesToQueryItem() throws {
        let address = try Address(string: "e3090a1309DfAC40352d03dEc6cCD9cAd213e76B")
        let intent = TransactionIntent(to: address)

        let url = DefaultDeepLinkGenerator().linkTo(transaction: intent)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let names = components?.queryItems?.map(\.name) ?? []

        XCTAssertTrue(names.contains("to"))
    }
}
