import Foundation

/// Error carrying the HTTP status so repositories can map codes (e.g. 409 → active
/// session, 400 → missing params), mirroring Android's `response.code()` inspection.
struct APIError: Error {
    let statusCode: Int
    let data: Data?
}

/// REST surface, ported from Android `data/remote/EmailApiService.kt` (Retrofit).
protocol EmailApi {
    func getTempEmail(query: [String: String]?) async throws -> TempEmailResponse
    func activateEmail(_ request: TempEmailResponse) async throws
    func getEmailsByAddress(email: String) async throws -> EmailsResponse
    func getEmailDomains() async throws -> DomainResponse
    func createCustomEmail(_ request: CustomEmailRequest) async throws -> CustomEmailResponse
    func getCurrentTimestamp() async throws -> Int
    func getActiveCustomEmails(deviceId: String) async throws -> ActiveCustomEmailResponse
}

/// URLSession implementation. Base URL is AES-decrypted at construction (Android does
/// this in `NetworkModule.provideEmailApi`).
final class EmailApiService: EmailApi {
    private let baseURL: URL
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    /// Convenience initializer that decrypts the base URL from `SecretConstants`.
    convenience init(session: URLSession = .shared) throws {
        let urlString = try Decryptor.decryptBase64(
            encryptedBase64: SecretConstants.BURL,
            keyBase64: SecretConstants.BKEY,
            ivBase64: SecretConstants.BIV
        )
        guard let url = URL(string: urlString) else {
            throw APIError(statusCode: -1, data: nil)
        }
        self.init(baseURL: url, session: session)
    }

    // MARK: - EmailApi

    func getTempEmail(query: [String: String]? = nil) async throws -> TempEmailResponse {
        try await get("get-email", query: query)
    }

    func activateEmail(_ request: TempEmailResponse) async throws {
        _ = try await send(path: "activate-email", method: "POST", body: request) as EmptyResponse
    }

    func getEmailsByAddress(email: String) async throws -> EmailsResponse {
        try await get("get-emails-by-address", query: ["email": email])
    }

    func getEmailDomains() async throws -> DomainResponse {
        try await get("getEmailDomains")
    }

    func createCustomEmail(_ request: CustomEmailRequest) async throws -> CustomEmailResponse {
        try await send(path: "custom-email/create", method: "POST", body: request)
    }

    func getCurrentTimestamp() async throws -> Int {
        try await get("get-currenttimestamp")
    }

    func getActiveCustomEmails(deviceId: String) async throws -> ActiveCustomEmailResponse {
        try await get("custom-email/list", query: ["deviceId": deviceId])
    }

    // MARK: - Request plumbing

    private func url(_ path: String, query: [String: String]?) -> URL {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        if let query, !query.isEmpty {
            components?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        return components?.url ?? baseURL.appendingPathComponent(path)
    }

    private func get<Response: Decodable>(_ path: String, query: [String: String]? = nil) async throws -> Response {
        var request = URLRequest(url: url(path, query: query))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return try await perform(request)
    }

    private func send<Body: Encodable, Response: Decodable>(
        path: String, method: String, body: Body
    ) async throws -> Response {
        var request = URLRequest(url: url(path, query: nil))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(body)
        return try await perform(request)
    }

    private func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError(statusCode: -1, data: data)
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError(statusCode: http.statusCode, data: data)
        }
        if Response.self == EmptyResponse.self {
            return EmptyResponse() as! Response
        }
        return try decoder.decode(Response.self, from: data)
    }
}

/// Sentinel for endpoints whose body we ignore (e.g. `activate-email`).
private struct EmptyResponse: Decodable {}
