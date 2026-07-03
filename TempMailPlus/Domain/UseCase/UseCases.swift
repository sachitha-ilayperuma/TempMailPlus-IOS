import Foundation

// Use cases ported from Android `domain/usecase/*`.
// Each is a thin, injectable wrapper over a repository (mirrors the Kotlin
// `operator fun invoke`, expressed here as `callAsFunction`).

struct GenerateTempEmailUseCase {
    let repository: TempEmailRepository
    func callAsFunction(loadComEmail: Bool) async throws -> TempEmail {
        try await repository.getTempEmail(loadComEmail: loadComEmail)
    }
}

struct ActivateEmailUseCase {
    let repository: TempEmailRepository
    func callAsFunction(email: String, reservationId: String) async throws {
        try await repository.activateEmail(email: email, reservationId: reservationId)
    }
}

struct GetEmailsByAddressUseCase {
    let repository: TempEmailRepository
    func callAsFunction(_ email: String) async throws -> [Email] {
        try await repository.getEmailsByAddress(email)
    }
}

struct GetEmailByIDUseCase {
    let repository: TempEmailRepository
    func callAsFunction(_ emailID: String) -> Email? {
        repository.getEmailById(emailID)
    }
}

struct GetEmailDomainsUseCase {
    let repository: TempEmailRepository
    func callAsFunction() async throws -> [String] {
        try await repository.getEmailDomains()
    }
}

struct GetActiveCustomEmailsUseCase {
    let repository: TempEmailRepository
    func callAsFunction() async throws -> [ActiveCustomEmail] {
        try await repository.getActiveCustomEmailsList()
    }
}

struct CreateCustomEmailUseCase {
    let repository: TempEmailRepository
    func callAsFunction(prefix: String, domain: String) async throws -> CustomEmailResponse {
        try await repository.addCustomEmail(prefix: prefix, domain: domain)
    }
}

struct SyncServerTimeUseCase {
    let repository: TimeRepository
    @discardableResult
    func callAsFunction() async -> Resource<Int> {
        await repository.syncServerTime()
    }
}

// WebSocket use cases (Phase 3).
struct ObserveEmailsUseCase {
    let repository: TempEmailRepository
    func callAsFunction() -> AsyncStream<Email> { repository.observeEmails() }
}

struct ConnectWebSocketUseCase {
    let repository: TempEmailRepository
    func callAsFunction(email: String) { repository.connectWebSocket(email: email) }
}

struct DisconnectWebSocketUseCase {
    let repository: TempEmailRepository
    func callAsFunction() { repository.disconnectWebSocket() }
}

struct ValidateUsernameUseCase {
    let validator: UsernameValidator
    let resourceProvider: ResourceProvider
    func callAsFunction(_ username: String) -> ValidationResult {
        validator.validate(username, resource: resourceProvider)
    }
}

/// Ported from Android `ValidateDailyEmailLimitUseCase` — 5 custom emails/day, keyed on
/// the user's local date derived from secure server time.
struct ValidateDailyEmailLimitUseCase {
    static let maxEmailsPerDay = 5
    let repository: EmailLimitRepository

    func callAsFunction() async -> Resource<Bool> {
        let serverResult = await repository.getServerTimestamp()
        let serverTime: Int
        switch serverResult {
        case .success(let t): serverTime = t
        case .failure(let e): return .failure(e)
        case .loading: return .failure(NSError(domain: "EmailLimit", code: -1))
        }

        // Convert server time (millis) to the user's local date (yyyy-MM-dd).
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        let todayDate = formatter.string(from: Date(timeIntervalSince1970: Double(serverTime) / 1000.0))

        let storedDate = await repository.getDailyEmailDay()
        let storedCount = await repository.getDailyEmailCount()

        if storedDate != todayDate {
            await repository.updateDailyUsage(count: 1, lastDate: todayDate)
            return .success(true)
        } else if storedCount < Self.maxEmailsPerDay {
            await repository.updateDailyUsage(count: storedCount + 1, lastDate: todayDate)
            return .success(true)
        } else {
            return .success(false)
        }
    }
}

/// Ported from Android `TempEmailUseCases` aggregator.
struct TempEmailUseCases {
    let generateTempEmail: GenerateTempEmailUseCase
    let activateEmail: ActivateEmailUseCase
    let getEmailsByAddress: GetEmailsByAddressUseCase
    let getEmailById: GetEmailByIDUseCase
    let getEmailDomainsUseCase: GetEmailDomainsUseCase
    let getActiveCustomEmailsUseCase: GetActiveCustomEmailsUseCase
    let createCustomEmailUseCase: CreateCustomEmailUseCase
    let syncServerTimeUseCase: SyncServerTimeUseCase
    let observeEmailsUseCase: ObserveEmailsUseCase
    let connectWebSocketUseCase: ConnectWebSocketUseCase
    let disconnectWebSocketUseCase: DisconnectWebSocketUseCase
}
