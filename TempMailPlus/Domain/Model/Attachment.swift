import Foundation

// Ported from Android `domain/model/Attachment.kt`.
struct Attachment: Equatable {
    let fileName: String
    let contentType: String
    let size: Double
    let url: String
}
