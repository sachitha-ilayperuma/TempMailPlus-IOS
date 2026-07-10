import UserNotifications

/// Ported from Android's notification permission request (`HomeScreen.kt`'s
/// `POST_NOTIFICATIONS` launcher) and `WebSocketService.showNotification` (posts to the
/// "email_channel" with the sender name as title, subject as body).
///
/// Per IMPLEMENTATION_PLAN.md §7 (no-backend-changes constraint): this only fires while the
/// app is foreground/active, since the WebSocket (its only trigger) doesn't run in the
/// background on iOS. `BackgroundRefreshManager` is the best-effort supplement for the
/// backgrounded case.
final class LocalNotificationManager {
    private let center = UNUserNotificationCenter.current()

    /// Matches Android: only prompts if the user hasn't already declined (tracked via
    /// `DataStoreManager.isNotificationPermissionDeclined`, checked by the caller).
    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Posts a local notification for a newly-received email — the iOS analog of Android's
    /// `WebSocketService.showNotification(email)`. Tapping it just opens the app (Android's
    /// "navigate to inbox on tap" is commented out in the source, so this doesn't attempt a
    /// deep link either — matched, not added as a new feature).
    func postNewMailNotification(fromName: String, subject: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = fromName.isEmpty ? "New email" : fromName
        content.body = subject
        content.sound = .default

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        center.add(request)
    }
}
