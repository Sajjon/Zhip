@testable import AppFeature
import XCTest

final class KeyValueStoreKeychainKeyTests: XCTestCase {
    private var store: SecurePersistence!

    override func setUp() {
        super.setUp()
        store = TestStoreFactory.makeSecurePersistence()
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    // MARK: - wallet

    func test_wallet_initiallyNil() {
        XCTAssertNil(store.wallet)
    }

    func test_hasConfiguredWallet_initiallyFalse() {
        XCTAssertFalse(store.hasConfiguredWallet)
    }

    func test_saveWallet_persistsAndCanLoad() {
        let wallet = TestWalletFactory.makeWallet()
        store.save(wallet: wallet)
        XCTAssertNotNil(store.wallet)
        XCTAssertTrue(store.hasConfiguredWallet)
    }

    func test_deleteWallet_removesPersistedWallet() {
        store.save(wallet: TestWalletFactory.makeWallet())
        XCTAssertTrue(store.hasConfiguredWallet)

        store.deleteWallet()
        XCTAssertFalse(store.hasConfiguredWallet)
        XCTAssertNil(store.wallet)
    }

    // MARK: - pincode

    func test_pincode_initiallyNil() {
        XCTAssertNil(store.pincode)
    }

    func test_hasConfiguredPincode_initiallyFalse() {
        XCTAssertFalse(store.hasConfiguredPincode)
    }

    func test_savePincode_persistsAndCanLoad() throws {
        let pincode = try Pincode(digits: [.zero, .one, .two, .three])
        store.save(pincode: pincode)
        XCTAssertNotNil(store.pincode)
        XCTAssertTrue(store.hasConfiguredPincode)
    }

    func test_deletePincode_removesPersistedPincode() throws {
        let pincode = try Pincode(digits: [.nine, .eight, .seven, .six])
        store.save(pincode: pincode)
        XCTAssertTrue(store.hasConfiguredPincode)

        store.deletePincode()
        XCTAssertFalse(store.hasConfiguredPincode)
        XCTAssertNil(store.pincode)
    }
}
