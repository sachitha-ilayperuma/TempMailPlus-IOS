import XCTest
@testable import TempMailPlus

/// Verifies the CommonCrypto AES/CBC/PKCS7 port produces the same plaintext the Android
/// `Decryptor` does — i.e. valid base/WebSocket URLs. This is the key correctness check
/// for Phase 1: if the crypto is wrong, nothing networks.
final class DecryptorTests: XCTestCase {

    func test_decryptsBaseURL_toValidHTTPURL() throws {
        let url = try Decryptor.decryptBase64(
            encryptedBase64: SecretConstants.BURL,
            keyBase64: SecretConstants.BKEY,
            ivBase64: SecretConstants.BIV
        )
        XCTAssertTrue(url.hasPrefix("http"), "Base URL should start with http(s): got \(url)")
        XCTAssertNotNil(URL(string: url), "Base URL should be a parseable URL: \(url)")
    }

    func test_decryptsWebSocketURL_toValidWSURL() throws {
        let url = try Decryptor.decryptBase64(
            encryptedBase64: SecretConstants.WURL,
            keyBase64: SecretConstants.BKEY,
            ivBase64: SecretConstants.BIV
        )
        XCTAssertTrue(url.hasPrefix("ws"), "WebSocket URL should start with ws(s): got \(url)")
        XCTAssertNotNil(URL(string: url), "WebSocket URL should be parseable: \(url)")
    }

    func test_apiService_buildsFromDecryptedBaseURL() throws {
        // Convenience init decrypts internally; should not throw.
        XCTAssertNoThrow(try EmailApiService())
    }
}
