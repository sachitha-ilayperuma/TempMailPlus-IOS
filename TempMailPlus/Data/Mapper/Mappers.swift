import Foundation

// Ported from Android `data/mapper/toDomain.kt`.

extension EmailDto {
    func toDomain() -> Email {
        Email(
            id: id,
            from: from,
            fromName: fromName,
            subject: subject,
            receivedAt: date.flatMap { Self.parseDateToMillis($0) } ?? 0,
            body: content,
            isRead: read,
            attachments: (attachments ?? []).map { $0.toDomain() }
        )
    }

    /// Parses an ISO-8601 timestamp to epoch millis; falls back to "now" (matches
    /// Android's `Instant.parse(...)` with a `System.currentTimeMillis()` fallback).
    private static func parseDateToMillis(_ dateStr: String) -> Int {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: dateStr) { return Int(d.timeIntervalSince1970 * 1000) }
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: dateStr) { return Int(d.timeIntervalSince1970 * 1000) }
        return currentTimeMillis()
    }
}

extension AttachmentDto {
    func toDomain() -> Attachment {
        Attachment(fileName: fileName, contentType: contentType, size: size, url: url)
    }
}

extension ActiveCustomEmailDto {
    func toDomain() -> ActiveCustomEmail {
        ActiveCustomEmail(email: email, expiresAt: expiresAt)
    }
}
