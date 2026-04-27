import XCTest
@testable import Zhip

final class DeepLinkTests: XCTestCase {
    private let validAddressString = "e3090a1309DfAC40352d03dEc6cCD9cAd213e76B"

    func test_init_urlWithoutQueryItems_returnsNil() throws {
        let url = try XCTUnwrap(URL(string: "https://zhip.app/send"))
        XCTAssertNil(DeepLink(url: url))
    }

    func test_init_unknownPath_returnsNil() throws {
        let url = try XCTUnwrap(URL(string: "https://zhip.app/unknown?to=\(validAddressString)"))
        XCTAssertNil(DeepLink(url: url))
    }

    func test_init_sendPath_withValidAddress_returnsSend() throws {
        let url = try XCTUnwrap(URL(string: "https://zhip.app/send?to=\(validAddressString)"))
        guard let sut = DeepLink(url: url) else {
            return XCTFail("expected non-nil DeepLink")
        }
        XCTAssertNotNil(sut.asTransaction)
    }

    func test_init_sendPath_withoutValidTransaction_returnsNil() throws {
        let url = try XCTUnwrap(URL(string: "https://zhip.app/send?foo=bar"))
        XCTAssertNil(DeepLink(url: url))
    }

    func test_path_rawValues() {
        XCTAssertEqual(DeepLink.Path.send.rawValue, "/send")
    }

    func test_asTransaction_extractsIntent() throws {
        let url = try XCTUnwrap(URL(string: "https://zhip.app/send?to=\(validAddressString)"))
        let sut = DeepLink(url: url)
        XCTAssertNotNil(sut?.asTransaction)
    }
}
