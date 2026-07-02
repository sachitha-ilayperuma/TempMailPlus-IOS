import Foundation

/// Ported from Android
/// `presentation/viewModel/utils/ActiveEmailRefreshReason.kt`.
/// Drives whether `refreshActiveEmails` performs a network fetch of custom emails or
/// rebuilds the active list locally.
enum ActiveEmailRefreshReason {
    case coldStart
    case newNormalEmail
    case newCustomEmail
    case normalEmailExpired
    case customEmailExpired
    case manualRefresh
    case skipFetchingEmail
}
