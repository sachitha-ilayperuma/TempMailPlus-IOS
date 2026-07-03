import Foundation
import os

/// Ported from Android `data/analytics/FirebaseAnalyticsTracker.kt` — structurally the
/// same shape (one `logEvent` mapping an `AnalyticsEvent` to a name + param dictionary),
/// but backed by `os.Logger` instead of the Firebase Analytics SDK.
///
/// Real Firebase requires a `GoogleService-Info.plist` (an iOS Firebase app registration)
/// which doesn't exist yet — see IMPLEMENTATION_PLAN.md §8 / PROGRESS.md open items.
/// Adding the Firebase SDK without real credentials would either crash at
/// `FirebaseApp.configure()` or need defensive no-op guards, so this project keeps the
/// same `AnalyticsTracker` protocol seam and logs events locally (verifiable now) until
/// real Firebase credentials are available — swapping in a `FirebaseAnalyticsTracker` at
/// that point is a single new file plus one line in `AppContainer`.
final class AnalyticsTrackerImpl: AnalyticsTracker {
    private let logger = Logger(subsystem: "com.digitaldevs.tempmailplus", category: "Analytics")

    func logEvent(_ event: AnalyticsEvent) {
        if event.params.isEmpty {
            logger.info("event: \(event.name, privacy: .public)")
        } else {
            logger.info("event: \(event.name, privacy: .public) params: \(String(describing: event.params), privacy: .public)")
        }
    }
}
