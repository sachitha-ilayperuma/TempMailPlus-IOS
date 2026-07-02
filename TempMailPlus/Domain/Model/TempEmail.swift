import Foundation

// Ported from Android `domain/model/TempEmail.kt`.
// Codable field names match the Android Gson JSON keys so persisted values are
// interchangeable in shape (email, reservationId, loadedTimestamp, expiredTimestamp,
// isCustomEmail, isComMail).
struct TempEmail: Codable, Equatable {
    var email: String
    var reservationId: String
    var loadedTimestamp: Int = -1
    var expiredTimestamp: Int = -1
    var isCustomEmail: Bool = false
    var isComMail: Bool = false

    init(
        email: String,
        reservationId: String,
        loadedTimestamp: Int = -1,
        expiredTimestamp: Int = -1,
        isCustomEmail: Bool = false,
        isComMail: Bool = false
    ) {
        self.email = email
        self.reservationId = reservationId
        self.loadedTimestamp = loadedTimestamp
        self.expiredTimestamp = expiredTimestamp
        self.isCustomEmail = isCustomEmail
        self.isComMail = isComMail
    }

    // Tolerate missing keys (Gson-like), so older/partial persisted JSON still decodes.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        email = try c.decodeIfPresent(String.self, forKey: .email) ?? ""
        reservationId = try c.decodeIfPresent(String.self, forKey: .reservationId) ?? ""
        loadedTimestamp = try c.decodeIfPresent(Int.self, forKey: .loadedTimestamp) ?? -1
        expiredTimestamp = try c.decodeIfPresent(Int.self, forKey: .expiredTimestamp) ?? -1
        isCustomEmail = try c.decodeIfPresent(Bool.self, forKey: .isCustomEmail) ?? false
        isComMail = try c.decodeIfPresent(Bool.self, forKey: .isComMail) ?? false
    }
}
