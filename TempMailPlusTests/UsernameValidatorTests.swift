import XCTest
@testable import TempMailPlus

/// A deterministic ResourceProvider that echoes the key, so assertions don't depend on
/// localized copy.
private struct FakeResourceProvider: ResourceProvider {
    func string(_ key: String) -> String { key }
    func string(_ key: String, _ args: CVarArg...) -> String { key }
}

final class UsernameValidatorTests: XCTestCase {
    private let validator = UsernameValidator()
    private let resource = FakeResourceProvider()

    func test_blank_isInvalid() {
        let r = validator.validate("   ", resource: resource)
        XCTAssertFalse(r.isValid)
        XCTAssertEqual(r.errorMessage, StringKey.enterName)
    }

    func test_tooShort_isInvalid() {
        let r = validator.validate("ab", resource: resource)
        XCTAssertFalse(r.isValid)
        XCTAssertEqual(r.errorMessage, StringKey.tooShort)
    }

    func test_tooLong_isInvalid() {
        let r = validator.validate("abcdefghijklmnop", resource: resource) // 16 chars
        XCTAssertFalse(r.isValid)
        XCTAssertEqual(r.errorMessage, StringKey.tooLong)
    }

    func test_invalidCharacters_isInvalid() {
        let r = validator.validate("hello world", resource: resource) // space
        XCTAssertFalse(r.isValid)
        XCTAssertEqual(r.errorMessage, StringKey.invalidCharacters)
    }

    func test_forbiddenKeyword_isInvalid() {
        // "google" is a forbidden keyword with no earlier substring match in the list.
        let r = validator.validate("google", resource: resource)
        XCTAssertFalse(r.isValid)
        XCTAssertEqual(r.errorMessage, "\(StringKey.restrictedName) google")
    }

    func test_forbiddenKeyword_firstMatchWins() {
        // "mypaypal" contains both "pay" and "paypal"; "pay" appears first in the list,
        // so it wins — matching Android's in-order iteration exactly.
        let r = validator.validate("mypaypal", resource: resource)
        XCTAssertFalse(r.isValid)
        XCTAssertEqual(r.errorMessage, "\(StringKey.restrictedName) pay")
    }

    func test_validUsername_isValid() {
        let r = validator.validate("john.doe-1", resource: resource)
        XCTAssertTrue(r.isValid)
        XCTAssertNil(r.errorMessage)
    }

    func test_allowedSpecialChars_areValid() {
        XCTAssertTrue(validator.validate("a_b-c.d", resource: resource).isValid)
    }
}
