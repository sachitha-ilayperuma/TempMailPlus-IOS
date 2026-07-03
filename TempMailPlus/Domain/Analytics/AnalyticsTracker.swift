import Foundation

/// Ported from Android `domain/analytics/AnalyticsTracker.kt`.
protocol AnalyticsTracker {
    func logEvent(_ event: AnalyticsEvent)
}
