import Foundation

// Repository protocols ported from Android `domain/repository/*`.
// WebSocket methods (Android's `observeEmails`/`connect`/`disconnect`) are added to
// `TempEmailRepository` in Phase 3. Billing (`BillingRepository`) is added in Phase 6.

/// Android `TempEmailRepository` — REST surface (Phase 1).
protocol TempEmailRepository {
    func getTempEmail(loadComEmail: Bool) async throws -> TempEmail
    func activateEmail(email: String, reservationId: String) async throws
    func getEmailsByAddress(_ email: String) async throws -> [Email]
    func getEmailById(_ id: String) -> Email?
    func getEmailDomains() async throws -> [String]
    func addCustomEmail(prefix: String, domain: String) async throws -> CustomEmailResponse
    func getActiveCustomEmailsList() async throws -> [ActiveCustomEmail]
    func getServerTimestamp() async throws -> Int?
}

/// Android `TimeRepository`.
protocol TimeRepository {
    @discardableResult
    func syncServerTime() async -> Resource<Int>
    func getCurrentServerTimeMillis() async -> Int
}

/// Android `DeviceIdProvider`.
protocol DeviceIdProvider {
    func getDeviceId() async -> String
}

/// Android `EmailLimitRepository`.
protocol EmailLimitRepository {
    func getServerTimestamp() async -> Resource<Int>
    func getDailyEmailCount() async -> Int
    func getDailyEmailDay() async -> String
    func updateDailyUsage(count: Int, lastDate: String) async
}

/// Android `OnboardRepository`.
protocol OnboardRepository {
    func isFirstLaunch() async -> Bool
    func setFirstLaunch(_ isFirst: Bool) async
}
