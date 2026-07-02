import Foundation

// Ported the platform-agnostic helpers from Android `core/Extensions.kt`.
// (Android-only bits — Compose modifiers, DownloadManager, DataStore delegates — are
// intentionally omitted; their iOS equivalents live in the relevant screens/managers.)

extension Int {
    /// Epoch seconds are ~10 digits.
    var isEpochSeconds: Bool {
        self >= 1_000_000_000 && self <= 9_999_999_999
    }

    /// Normalizes an epoch value to milliseconds (seconds → millis, millis unchanged).
    var ensureEpochMillis: Int {
        isEpochSeconds ? self * 1000 : self
    }

    /// "MMM dd, yyyy 'at' HH:mm" in the current locale/timezone. `self` is epoch millis.
    func formatFullTime() -> String {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateFormat = "MMM dd, yyyy 'at' HH:mm"
        return f.string(from: Date(timeIntervalSince1970: Double(self) / 1000.0))
    }

    /// Relative "time ago" string. `self` is epoch millis.
    func getTimeAgo() -> String {
        let now = Date()
        let time = Date(timeIntervalSince1970: Double(self) / 1000.0)
        let seconds = now.timeIntervalSince(time)
        let minutes = Int(seconds / 60)
        let hours = Int(seconds / 3600)
        let days = Int(seconds / 86_400)

        switch true {
        case minutes < 1: return "Just now"
        case minutes < 60: return "\(minutes) min ago"
        case hours < 24: return "\(hours) hour\(hours > 1 ? "s" : "") ago"
        case days == 1: return "Yesterday"
        case days < 7: return "\(days) days ago"
        default:
            let f = DateFormatter()
            f.locale = Locale.current
            f.dateFormat = "MMM d, yyyy"
            return f.string(from: time)
        }
    }

    /// "yyyy-MM-dd" in UTC (matches Android `toLocalDateString`). `self` is epoch millis.
    func toLocalDateString() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date(timeIntervalSince1970: Double(self) / 1000.0))
    }
}

extension Double {
    /// Human-readable file size, matching Android `formatFileSize`.
    func formatFileSize() -> String {
        let kb = 1024.0
        let mb = kb * 1024
        let gb = mb * 1024
        switch self {
        case ..<kb: return "\(Int(self)) B"
        case ..<mb: return String(format: "%.2f KB", self / kb)
        case ..<gb: return String(format: "%.2f MB", self / mb)
        default:    return String(format: "%.2f GB", self / gb)
        }
    }
}

/// Current wall-clock time in epoch milliseconds (the iOS analog of
/// `System.currentTimeMillis()`).
func currentTimeMillis() -> Int {
    Int(Date().timeIntervalSince1970 * 1000)
}
