import BackgroundTasks
import Foundation

/// Best-effort background polling, per IMPLEMENTATION_PLAN.md §7: since there is no
/// backend push and iOS forbids long-lived background sockets, this is the only
/// no-backend-change way to get *any* chance of a background alert. iOS schedules
/// `BGAppRefreshTask` opportunistically (typically no sooner than ~15 min, throttled by
/// usage patterns) and **does not run after the user force-quits the app** — given temp
/// emails expire in 5–10 minutes, this will frequently miss the window. It is a
/// supplement to the foreground WebSocket + fetch-on-open, never a replacement; the
/// inbox is always correct on open regardless of whether this ever fires.
///
/// No Android equivalent exists to port from — Android's parity story here is the
/// foreground service, which iOS does not permit; this class is iOS's own best-effort
/// answer to the same constraint, not a port of anything.
final class BackgroundRefreshManager {
    static let taskIdentifier = "com.digitaldevs.tempmailplus.refresh"

    private let dataStore: DataStoreManager
    private let tempEmailUseCases: TempEmailUseCases
    private let notificationManager: LocalNotificationManager

    init(dataStore: DataStoreManager, tempEmailUseCases: TempEmailUseCases, notificationManager: LocalNotificationManager) {
        self.dataStore = dataStore
        self.tempEmailUseCases = tempEmailUseCases
        self.notificationManager = notificationManager
    }

    /// Must be called before the app finishes launching (from `AppContainer.init()`,
    /// itself constructed early via `@StateObject` in `TempMailPlusApp`).
    func registerTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil) { [weak self] task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            self?.handle(refreshTask)
        }
    }

    /// Schedules the next opportunistic run. Safe to call repeatedly (e.g. on every
    /// backgrounding) — a new request simply replaces any pending one.
    func scheduleNextRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // no sooner than 15 min
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handle(_ task: BGAppRefreshTask) {
        scheduleNextRefresh() // keep the chain going regardless of this run's outcome

        let work = Task {
            await checkForNewMail()
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = { work.cancel() }
    }

    private func checkForNewMail() async {
        let selected = dataStore.getSelectedTempEmail()
        guard !selected.email.isEmpty else { return }

        guard let emails = try? await tempEmailUseCases.getEmailsByAddress(selected.email) else { return }

        let seenIds = Set(dataStore.getSeenEmailIds())
        let newEmails = emails.filter { !seenIds.contains($0.id) }
        dataStore.setSeenEmailIds(emails.map(\.id))

        guard !newEmails.isEmpty else { return }
        dataStore.setHasNewEmail(true)
        for email in newEmails.prefix(3) { // cap notification spam on a big batch
            notificationManager.postNewMailNotification(fromName: email.fromName, subject: email.subject, identifier: email.id)
        }
    }
}
