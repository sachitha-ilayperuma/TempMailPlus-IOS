import Foundation

/// Ported from Android `data/repository/TempEmailRepositoryImpl.kt` (REST portion).
/// WebSocket wiring is added in Phase 3.
final class TempEmailRepositoryImpl: TempEmailRepository {
    private let api: EmailApi
    private let deviceIdProvider: DeviceIdProvider
    private var cachedEmails: [Email] = []

    init(api: EmailApi, deviceIdProvider: DeviceIdProvider) {
        self.api = api
        self.deviceIdProvider = deviceIdProvider
    }

    func getTempEmail(loadComEmail: Bool) async throws -> TempEmail {
        let response: TempEmailResponse
        if loadComEmail {
            response = try await api.getTempEmail(query: [
                "premium": "true",
                "timestamp": String(currentTimeMillis())
            ])
        } else {
            response = try await api.getTempEmail(query: nil)
        }
        return TempEmail(email: response.email, reservationId: response.reservationId)
    }

    func activateEmail(email: String, reservationId: String) async throws {
        try await api.activateEmail(TempEmailResponse(email: email, reservationId: reservationId))
    }

    func getEmailsByAddress(_ email: String) async throws -> [Email] {
        let response = try await api.getEmailsByAddress(email: email)
        let emails = response.emails.map { $0.toDomain() }
        cachedEmails = emails
        return emails
    }

    func getEmailById(_ id: String) -> Email? {
        cachedEmails.first { $0.id == id }
    }

    func getEmailDomains() async throws -> [String] {
        let response = try await api.getEmailDomains()
        guard let data = response.body.data(using: .utf8),
              let domains = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return domains
    }

    func addCustomEmail(prefix: String, domain: String) async throws -> CustomEmailResponse {
        let deviceId = await deviceIdProvider.getDeviceId()
        let request = CustomEmailRequest(prefix: prefix, domain: domain, deviceId: deviceId)
        do {
            return try await api.createCustomEmail(request)
        } catch let error as APIError {
            switch error.statusCode {
            case 409: throw CustomEmailError.activeSessionExists
            case 400: throw CustomEmailError.missingParameters
            default:  throw CustomEmailError.unknown(error.statusCode)
            }
        }
    }

    func getActiveCustomEmailsList() async throws -> [ActiveCustomEmail] {
        let deviceId = await deviceIdProvider.getDeviceId()
        let response = try await api.getActiveCustomEmails(deviceId: deviceId)
        return response.emails.map { $0.toDomain() }
    }

    func getServerTimestamp() async throws -> Int? {
        try await api.getCurrentTimestamp()
    }
}
