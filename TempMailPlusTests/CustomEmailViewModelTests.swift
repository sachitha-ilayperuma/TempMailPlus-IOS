import XCTest
@testable import TempMailPlus

// MARK: - Fakes

private final class FakeTempEmailRepository: TempEmailRepository {
    var createResult: Result<CustomEmailResponse, Error> = .success(CustomEmailResponse())

    func getTempEmail(loadComEmail: Bool) async throws -> TempEmail { TempEmail(email: "", reservationId: "") }
    func activateEmail(email: String, reservationId: String) async throws {}
    func getEmailsByAddress(_ email: String) async throws -> [Email] { [] }
    func getEmailById(_ id: String) -> Email? { nil }
    func getEmailDomains() async throws -> [String] { [] }
    func addCustomEmail(prefix: String, domain: String) async throws -> CustomEmailResponse {
        switch createResult {
        case .success(let r): return r
        case .failure(let e): throw e
        }
    }
    func getActiveCustomEmailsList() async throws -> [ActiveCustomEmail] { [] }
    func getServerTimestamp() async throws -> Int? { nil }
    func observeEmails() -> AsyncStream<Email> { AsyncStream { $0.finish() } }
    func connectWebSocket(email: String) {}
    func disconnectWebSocket() {}
}

private final class FakeTimeRepository: TimeRepository {
    func syncServerTime() async -> Resource<Int> { .success(0) }
    func getCurrentServerTimeMillis() async -> Int { 1_700_000_000_000 }
}

private struct EchoResourceProvider: ResourceProvider {
    func string(_ key: String) -> String { key }
    func string(_ key: String, _ args: CVarArg...) -> String { key }
}

@MainActor
final class CustomEmailViewModelTests: XCTestCase {
    private var repo: FakeTempEmailRepository!
    private var dataStore: DataStoreManager!
    private var analytics: FakeAnalyticsTracker!
    private var viewModel: CustomEmailViewModel!
    private let suite = "TempMailPlusTests.CustomEmailVM"

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        dataStore = DataStoreManager(defaults: defaults)
        repo = FakeTempEmailRepository()
        analytics = FakeAnalyticsTracker()
        viewModel = CustomEmailViewModel(
            createCustomEmailUseCase: CreateCustomEmailUseCase(repository: repo),
            validateUsernameUseCase: ValidateUsernameUseCase(validator: UsernameValidator(), resourceProvider: EchoResourceProvider()),
            dataStore: dataStore,
            timeProvider: TimeProvider(timeRepository: FakeTimeRepository()),
            rewardedAdManager: RewardedAdManager(),
            analyticsTracker: analytics
        )
    }

    func test_createCustomEmail_invalidUsername_setsErrorWithoutNetworkCall() {
        viewModel.createCustomEmail(prefix: "ab", domain: "x.com") // too short
        XCTAssertEqual(viewModel.uiState.errorMessage, StringKey.tooShort)
        XCTAssertFalse(viewModel.uiState.isProcessing)
    }

    func test_createCustomEmail_success_populatesState() async {
        repo.createResult = .success(CustomEmailResponse(
            message: "ok", code: "SUCCESS", email: "john@x.com", reservationId: "r1", expiresAt: 123
        ))
        viewModel.createCustomEmail(prefix: "john", domain: "x.com")
        // Allow the Task to run.
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(viewModel.uiState.selectedEmail, "john@x.com")
        XCTAssertEqual(viewModel.uiState.reservationID, "r1")
        XCTAssertEqual(viewModel.uiState.expiresAt, 123)
        XCTAssertNil(viewModel.uiState.errorMessage)
        XCTAssertFalse(viewModel.uiState.isProcessing)
    }

    func test_createCustomEmail_serverError_setsErrorMessage() async {
        repo.createResult = .success(CustomEmailResponse(code: "FAILED", error: "Prefix taken"))
        viewModel.createCustomEmail(prefix: "john", domain: "x.com")
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(viewModel.uiState.errorMessage, "Prefix taken")
        XCTAssertNil(viewModel.uiState.selectedEmail)
    }

    func test_createCustomEmail_activeSessionExists_mapsToLimitMessage() async {
        // message(for:) resolves via String(localized:) (real Localizable.strings), not the
        // injected fake ResourceProvider — assert against the actual localized copy.
        repo.createResult = .failure(CustomEmailError.activeSessionExists)
        viewModel.createCustomEmail(prefix: "john", domain: "x.com")
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(viewModel.uiState.errorMessage, String(localized: "error_email_limit_reached"))
    }

    func test_refreshCanCreateForLockedUser_trueWhenNoFreeUsageAndNoCustomEmail() {
        // getFreeCustomEmailExpiredTimestamp() defaults to 0 → "free" per Android semantics.
        viewModel.refreshCanCreateForLockedUser(activeEmails: [])
        XCTAssertTrue(viewModel.uiState.canCreateForLockedUser)
    }

    func test_refreshCanCreateForLockedUser_falseWhenActiveCustomEmailExists() {
        let custom = TempEmail(email: "c@x.com", reservationId: "", isCustomEmail: true)
        viewModel.refreshCanCreateForLockedUser(activeEmails: [custom])
        XCTAssertFalse(viewModel.uiState.canCreateForLockedUser)
    }

    func test_refreshCanCreateForLockedUser_falseAfterFreeTimestampSaved() {
        dataStore.saveFreeCustomEmailExpiredTimestamp(9_999_999_999_999)
        viewModel.refreshCanCreateForLockedUser(activeEmails: [])
        XCTAssertFalse(viewModel.uiState.canCreateForLockedUser)
    }

    func test_handleLockedUserCustomEmail_routesToAdOrSubscription() {
        viewModel.handleLockedUserCustomEmail(canCreateForLockedUser: true)
        XCTAssertTrue(viewModel.uiState.showRewardedAdConfirmPopup)
        XCTAssertFalse(viewModel.uiState.showSubscriptionDialog)

        viewModel.handleLockedUserCustomEmail(canCreateForLockedUser: false)
        XCTAssertFalse(viewModel.uiState.showRewardedAdConfirmPopup)
        XCTAssertTrue(viewModel.uiState.showSubscriptionDialog)
    }

    func test_resetCustomEmailState_onlyResetsFourFields() async {
        repo.createResult = .success(CustomEmailResponse(code: "SUCCESS", email: "e@x.com", reservationId: "r", expiresAt: 5))
        viewModel.createCustomEmail(prefix: "john", domain: "x.com")
        try? await Task.sleep(nanoseconds: 50_000_000)
        viewModel.refreshCanCreateForLockedUser(activeEmails: [])
        let canCreateBefore = viewModel.uiState.canCreateForLockedUser

        viewModel.resetCustomEmailState()

        XCTAssertNil(viewModel.uiState.selectedEmail)
        XCTAssertNil(viewModel.uiState.errorMessage)
        XCTAssertNil(viewModel.uiState.successMessage)
        XCTAssertFalse(viewModel.uiState.isProcessing)
        // Faithful to Android: reservationID/expiresAt/canCreateForLockedUser are untouched.
        XCTAssertEqual(viewModel.uiState.reservationID, "r")
        XCTAssertEqual(viewModel.uiState.expiresAt, 5)
        XCTAssertEqual(viewModel.uiState.canCreateForLockedUser, canCreateBefore)
    }

    func test_logCustomEmailClicked_logsEventWithSubscriptionFlag() {
        viewModel.logCustomEmailClicked(isSubscribed: true)
        XCTAssertEqual(analytics.loggedEvents.count, 1)
        guard case .clickCustomEmail(let isPremium) = analytics.loggedEvents[0] else {
            return XCTFail("expected .clickCustomEmail event")
        }
        XCTAssertTrue(isPremium)
    }
}
