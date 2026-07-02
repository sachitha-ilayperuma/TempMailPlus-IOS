import Foundation

// Ported from Android `domain/model/ActiveCustomEmail.kt`.
struct ActiveCustomEmail: Equatable {
    let email: String
    let expiresAt: Int   // epoch (seconds or millis; normalize via ensureEpochMillis)
}
