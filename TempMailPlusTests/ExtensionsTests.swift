import XCTest
@testable import TempMailPlus

final class ExtensionsTests: XCTestCase {

    func test_isEpochSeconds() {
        XCTAssertTrue(1_700_000_000.isEpochSeconds)      // ~2023 in seconds
        XCTAssertFalse(1_700_000_000_000.isEpochSeconds) // millis
        XCTAssertFalse(0.isEpochSeconds)
    }

    func test_ensureEpochMillis_convertsSeconds() {
        XCTAssertEqual(1_700_000_000.ensureEpochMillis, 1_700_000_000_000)
    }

    func test_ensureEpochMillis_leavesMillisUnchanged() {
        XCTAssertEqual(1_700_000_000_000.ensureEpochMillis, 1_700_000_000_000)
    }

    func test_formatFileSize() {
        XCTAssertEqual((512.0).formatFileSize(), "512 B")
        XCTAssertEqual((2048.0).formatFileSize(), "2.00 KB")
        XCTAssertEqual((5_242_880.0).formatFileSize(), "5.00 MB")
    }

    func test_toLocalDateString_isUTC() {
        // 2023-11-14T22:13:20Z  → 1700000000000 ms
        XCTAssertEqual((1_700_000_000_000).toLocalDateString(), "2023-11-14")
    }
}
