import XCTest
@testable import TempMailPlus

final class DataStoreManagerTests: XCTestCase {
    private var defaults: UserDefaults!
    private var store: DataStoreManager!
    private let suite = "TempMailPlusTests.DataStore"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        store = DataStoreManager(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    func test_firstLaunch_defaultsToTrue() {
        XCTAssertTrue(store.isFirstLaunch())
        store.setFirstLaunch(false)
        XCTAssertFalse(store.isFirstLaunch())
    }

    func test_themeMode_roundTrips() {
        XCTAssertFalse(store.getThemeMode()) // default light
        store.setThemeMode(true)
        XCTAssertTrue(store.getThemeMode())
    }

    func test_serverTimeOffset_roundTrips() {
        store.saveServerTimeOffset(-4200)
        XCTAssertEqual(store.getServerTimeOffset(), -4200)
    }

    func test_tempEmail_roundTripsAsJSON() {
        let temp = TempEmail(
            email: "abc@temp-mail.com", reservationId: "r-1",
            loadedTimestamp: 111, expiredTimestamp: 222,
            isCustomEmail: true, isComMail: true
        )
        store.saveSelectedTempEmail(temp)
        XCTAssertEqual(store.getSelectedTempEmail(), temp)
    }

    func test_emptyTempEmail_whenMissing() {
        let empty = store.getSelectedTempEmail()
        XCTAssertEqual(empty.email, "")
        XCTAssertEqual(empty.reservationId, "")
    }

    func test_dailyUsage_roundTrips() {
        store.updateDailyEmailCount(count: 3, lastDate: "2026-07-02")
        XCTAssertEqual(store.getDailyEmailCount(), 3)
        XCTAssertEqual(store.getDailyEmailDate(), "2026-07-02")
    }
}
