import Foundation

/// Ported from Android `domain/util/error/CustomEmailError.kt` + `CustomEmailException.kt`.
/// Collapsed into a single Swift `Error` enum (no separate exception type needed).
enum CustomEmailError: Error, Equatable {
    case activeSessionExists   // HTTP 409
    case missingParameters     // HTTP 400
    case unknown(Int)          // other HTTP status
}
