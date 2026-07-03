import Foundation
import Combine

// Repository protocols ported from Android `domain/repository/*`.

/// Android `TempEmailRepository` — REST surface (Phase 1) + WebSocket (Phase 3).
protocol TempEmailRepository {
    func getTempEmail(loadComEmail: Bool) async throws -> TempEmail
    func activateEmail(email: String, reservationId: String) async throws
    func getEmailsByAddress(_ email: String) async throws -> [Email]
    func getEmailById(_ id: String) -> Email?
    func getEmailDomains() async throws -> [String]
    func addCustomEmail(prefix: String, domain: String) async throws -> CustomEmailResponse
    func getActiveCustomEmailsList() async throws -> [ActiveCustomEmail]
    func getServerTimestamp() async throws -> Int?

    // WebSocket (Phase 3)
    func observeEmails() -> AsyncStream<Email>
    func connectWebSocket(email: String)
    func disconnectWebSocket()
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

/// Android `BillingRepository` (Phase 6, backed by StoreKit 2).
protocol BillingRepository {
    func getSubscriptionStatus() -> AnyPublisher<SubscriptionStatus, Never>
    func refreshSubscriptionStatus() async
    func startSubscriptionPurchase(productId: String) async
}
