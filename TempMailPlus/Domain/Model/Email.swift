import Foundation

// Ported from Android `domain/model/Email.kt`.
struct Email: Identifiable, Equatable {
    let id: String
    let from: String
    let fromName: String
    let subject: String
    let receivedAt: Int          // epoch millis
    let body: String
    var isRead: Bool = false
    var attachments: [Attachment] = []
}
