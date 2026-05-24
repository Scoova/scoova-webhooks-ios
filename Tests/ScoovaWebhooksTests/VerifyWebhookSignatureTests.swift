import XCTest
@testable import ScoovaWebhooks

final class VerifyWebhookSignatureTests: XCTestCase {

    // hex(hmac-sha256("hello", "secret"))
    let KNOWN = "88aab3ede8d3adf94d26ab90d3bafd4a2083070c3bcce9c014ee04a443847c0b"

    func testAcceptsBareHex() {
        XCTAssertTrue(verifyWebhookSignature(body: "hello", headerValue: KNOWN, secret: "secret"))
    }

    func testAcceptsSha256Prefix() {
        XCTAssertTrue(verifyWebhookSignature(body: "hello", headerValue: "sha256=\(KNOWN)", secret: "secret"))
    }

    func testRejectsWrongBody() {
        XCTAssertFalse(verifyWebhookSignature(body: "hellO", headerValue: KNOWN, secret: "secret"))
    }

    func testRejectsWrongSecret() {
        XCTAssertFalse(verifyWebhookSignature(body: "hello", headerValue: KNOWN, secret: "wrong"))
    }

    func testRejectsEmptyHeader() {
        XCTAssertFalse(verifyWebhookSignature(body: "hello", headerValue: nil, secret: "secret"))
        XCTAssertFalse(verifyWebhookSignature(body: "hello", headerValue: "", secret: "secret"))
    }

    func testRejectsLengthMismatchWithoutCrash() {
        XCTAssertFalse(verifyWebhookSignature(body: "hello", headerValue: "deadbeef", secret: "secret"))
    }
}
