import Foundation

// Codable mirrors of the Android Gson DTOs in `data/dto/*`.
// JSON keys match the Android `@SerializedName` values exactly.

struct TempEmailResponse: Codable {
    let email: String
    let reservationId: String
}

struct EmailsResponse: Codable {
    let emails: [EmailDto]
}

struct EmailDto: Codable {
    var id: String = ""
    var from: String = ""
    var fromName: String = ""
    var subject: String = ""
    var date: String? = ""
    var content: String = ""
    var read: Bool = false
    var attachments: [AttachmentDto]? = []

    enum CodingKeys: String, CodingKey {
        case id, from, fromName, subject, date, content, read, attachments
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? ""
        from = try c.decodeIfPresent(String.self, forKey: .from) ?? ""
        fromName = try c.decodeIfPresent(String.self, forKey: .fromName) ?? ""
        subject = try c.decodeIfPresent(String.self, forKey: .subject) ?? ""
        date = try c.decodeIfPresent(String.self, forKey: .date)
        content = try c.decodeIfPresent(String.self, forKey: .content) ?? ""
        read = try c.decodeIfPresent(Bool.self, forKey: .read) ?? false
        attachments = try c.decodeIfPresent([AttachmentDto].self, forKey: .attachments) ?? []
    }
}

struct AttachmentDto: Codable {
    let fileName: String
    let contentType: String
    let size: Double
    let url: String

    enum CodingKeys: String, CodingKey {
        case fileName = "filename"   // Android @SerializedName("filename")
        case contentType, size, url
    }
}

struct DomainResponse: Codable {
    let statusCode: Int
    let headers: [String: String]
    let body: String   // JSON string that itself decodes to [String]
}

struct CustomEmailRequest: Codable {
    let prefix: String
    let domain: String
    let deviceId: String
}

struct CustomEmailResponse: Codable {
    var message: String? = nil
    var code: String? = nil
    var email: String? = nil
    var reservationId: String? = nil
    var error: String? = nil
    var expiresAt: Int? = 0

    init(
        message: String? = nil, code: String? = nil, email: String? = nil,
        reservationId: String? = nil, error: String? = nil, expiresAt: Int? = 0
    ) {
        self.message = message; self.code = code; self.email = email
        self.reservationId = reservationId; self.error = error; self.expiresAt = expiresAt
    }

    enum CodingKeys: String, CodingKey {
        case message, code, email, reservationId, error, expiresAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        message = try c.decodeIfPresent(String.self, forKey: .message)
        code = try c.decodeIfPresent(String.self, forKey: .code)
        email = try c.decodeIfPresent(String.self, forKey: .email)
        reservationId = try c.decodeIfPresent(String.self, forKey: .reservationId)
        error = try c.decodeIfPresent(String.self, forKey: .error)
        expiresAt = try c.decodeIfPresent(Int.self, forKey: .expiresAt) ?? 0
    }
}

struct ActiveCustomEmailResponse: Codable {
    let code: String
    let count: Int
    let emails: [ActiveCustomEmailDto]
}

struct ActiveCustomEmailDto: Codable {
    let email: String
    let expiresAt: Int
}
