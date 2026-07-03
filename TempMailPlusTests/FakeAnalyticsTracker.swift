@testable import TempMailPlus

/// Shared test double — records logged events so tests can assert on them without a real
/// analytics backend.
final class FakeAnalyticsTracker: AnalyticsTracker {
    private(set) var loggedEvents: [AnalyticsEvent] = []

    func logEvent(_ event: AnalyticsEvent) {
        loggedEvents.append(event)
    }
}
