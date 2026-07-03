import Foundation
import Combine

/// Ported from Android `data/datasources/datastore/DataStoreManager.kt`.
/// Backed by `UserDefaults` (the iOS analog of Preferences DataStore). Accessors are
/// synchronous here (UserDefaults is synchronous); Android's `suspend`/`Flow` shapes are
/// represented as plain getters/setters. Reactive publishers for the few observed values
/// (subscription status, new-email flag, selected email) are added in Phase 2 when the
/// Home view model needs them.
///
/// `TempEmail` / `[SubscriptionInfo]` are persisted as JSON, matching the Android Gson
/// approach (the shape is identical; a fresh iOS install does not share storage with
/// Android).
final class DataStoreManager {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // Reactive streams for the values Android exposed as DataStore `Flow`s and which the
    // Home view model observes continuously (rather than one-shot reads). Backed by
    // CurrentValueSubjects updated on write — sufficient because iOS runs the socket
    // in-process (no separate service process like Android).
    let hasNewEmailSubject: CurrentValueSubject<Bool, Never>
    let isSubscribedSubject: CurrentValueSubject<Bool, Never>
    let subscriptionsSubject: CurrentValueSubject<[SubscriptionInfo], Never>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.hasNewEmailSubject = CurrentValueSubject(defaults.bool(forKey: PreferenceKeys.hasNewEmail))
        self.isSubscribedSubject = CurrentValueSubject(defaults.bool(forKey: PreferenceKeys.isSubscribed))
        let decoder = JSONDecoder()
        let storedPlans: [SubscriptionInfo] = defaults.data(forKey: PreferenceKeys.subscriptionInfo)
            .flatMap { try? decoder.decode([SubscriptionInfo].self, from: $0) } ?? []
        self.subscriptionsSubject = CurrentValueSubject(storedPlans)
    }

    // MARK: - Theme
    func getThemeMode() -> Bool { defaults.bool(forKey: PreferenceKeys.darkMode) }
    func setThemeMode(_ isDark: Bool) { defaults.set(isDark, forKey: PreferenceKeys.darkMode) }

    // MARK: - New email flag
    func hasNewEmail() -> Bool { defaults.bool(forKey: PreferenceKeys.hasNewEmail) }
    func setHasNewEmail(_ value: Bool) {
        defaults.set(value, forKey: PreferenceKeys.hasNewEmail)
        hasNewEmailSubject.send(value)
    }

    // MARK: - Notification permission
    func isNotificationPermissionDeclined() -> Bool { defaults.bool(forKey: PreferenceKeys.notiPermissionDeclined) }
    func setNotificationPermissionDeclined(_ value: Bool) { defaults.set(value, forKey: PreferenceKeys.notiPermissionDeclined) }

    // MARK: - Review flags
    func isReviewed() -> Bool { defaults.bool(forKey: PreferenceKeys.isReviewed) }
    func setReviewed(_ value: Bool) { defaults.set(value, forKey: PreferenceKeys.isReviewed) }

    func isClickedReviewLater() -> Bool { defaults.bool(forKey: PreferenceKeys.isClickedReviewLater) }
    func setClickedReviewLater(_ value: Bool) { defaults.set(value, forKey: PreferenceKeys.isClickedReviewLater) }

    func lastInappReviewTimestamp() -> Int { defaults.integer(forKey: PreferenceKeys.lastInappReviewTimestamp) }
    func setLastInappReviewTimestamp(_ value: Int) { defaults.set(value, forKey: PreferenceKeys.lastInappReviewTimestamp) }

    func lastCustomReviewTimestamp() -> Int { defaults.integer(forKey: PreferenceKeys.lastCustomReviewTimestamp) }
    func setLastCustomReviewTimestamp(_ value: Int) { defaults.set(value, forKey: PreferenceKeys.lastCustomReviewTimestamp) }

    // MARK: - First launch (default true)
    func isFirstLaunch() -> Bool { defaults.object(forKey: PreferenceKeys.isFirstLaunch) as? Bool ?? true }
    func setFirstLaunch(_ isFirst: Bool) { defaults.set(isFirst, forKey: PreferenceKeys.isFirstLaunch) }

    // MARK: - Subscription
    func isSubscribed() -> Bool { defaults.bool(forKey: PreferenceKeys.isSubscribed) }
    func setSubscribed(_ value: Bool) {
        defaults.set(value, forKey: PreferenceKeys.isSubscribed)
        isSubscribedSubject.send(value)
    }

    // MARK: - Daily custom-email usage
    func getDailyEmailCount() -> Int { defaults.integer(forKey: PreferenceKeys.customEmailCount) }
    func getDailyEmailDate() -> String { defaults.string(forKey: PreferenceKeys.customEmailLastDate) ?? "" }
    func updateDailyEmailCount(count: Int, lastDate: String) {
        defaults.set(count, forKey: PreferenceKeys.customEmailCount)
        defaults.set(lastDate, forKey: PreferenceKeys.customEmailLastDate)
    }

    // MARK: - Temp emails (JSON)
    func getTempEmail() -> TempEmail { readTempEmail(PreferenceKeys.tempEmail) }
    func saveTempEmail(_ temp: TempEmail) { writeTempEmail(temp, PreferenceKeys.tempEmail) }
    func clearTempEmail() { defaults.removeObject(forKey: PreferenceKeys.tempEmail) }

    func getNormalTempEmail() -> TempEmail { readTempEmail(PreferenceKeys.normalTempEmail) }
    func saveNormalTempEmail(_ temp: TempEmail) { writeTempEmail(temp, PreferenceKeys.normalTempEmail) }
    func clearNormalTempEmail() { defaults.removeObject(forKey: PreferenceKeys.normalTempEmail) }

    func getPastVersionCustomEmail() -> TempEmail { readTempEmail(PreferenceKeys.pastVersionCustomEmail) }
    func savePastVersionCustomEmail(_ temp: TempEmail) { writeTempEmail(temp, PreferenceKeys.pastVersionCustomEmail) }
    func clearPastVersionCustomEmail() { defaults.removeObject(forKey: PreferenceKeys.pastVersionCustomEmail) }

    func getSelectedTempEmail() -> TempEmail { readTempEmail(PreferenceKeys.selectedTempEmail) }
    func saveSelectedTempEmail(_ temp: TempEmail) { writeTempEmail(temp, PreferenceKeys.selectedTempEmail) }
    func clearSelectedTempEmail() { defaults.removeObject(forKey: PreferenceKeys.selectedTempEmail) }

    // MARK: - Subscriptions info (JSON)
    func saveSubscriptions(_ subscriptions: [SubscriptionInfo]) {
        if let data = try? encoder.encode(subscriptions) {
            defaults.set(data, forKey: PreferenceKeys.subscriptionInfo)
        }
        subscriptionsSubject.send(subscriptions)
    }
    func getSubscriptions() -> [SubscriptionInfo] {
        guard let data = defaults.data(forKey: PreferenceKeys.subscriptionInfo),
              let list = try? decoder.decode([SubscriptionInfo].self, from: data) else { return [] }
        return list
    }

    // MARK: - Device id
    func getDeviceIdOrNil() -> String? { defaults.string(forKey: PreferenceKeys.deviceId) }
    func saveDeviceId(_ deviceId: String) { defaults.set(deviceId, forKey: PreferenceKeys.deviceId) }

    // MARK: - Server time offset
    func saveServerTimeOffset(_ offset: Int) { defaults.set(offset, forKey: PreferenceKeys.serverTimeOffset) }
    func getServerTimeOffset() -> Int { defaults.integer(forKey: PreferenceKeys.serverTimeOffset) }

    // MARK: - Free custom-email expiry
    func saveFreeCustomEmailExpiredTimestamp(_ value: Int) { defaults.set(value, forKey: PreferenceKeys.freeCustomEmailTimestamp) }
    func getFreeCustomEmailExpiredTimestamp() -> Int { defaults.integer(forKey: PreferenceKeys.freeCustomEmailTimestamp) }

    // MARK: - First-launch email load
    func setEmailLoadedOnFirstLaunch(_ value: Bool) { defaults.set(value, forKey: PreferenceKeys.isEmailLoaded) }
    func isEmailLoadedOnFirstLaunch() -> Bool { defaults.bool(forKey: PreferenceKeys.isEmailLoaded) }

    // MARK: - Service timeout
    func setServiceTimedOut(_ value: Bool) { defaults.set(value, forKey: PreferenceKeys.isServiceTimedOut) }
    func isServiceTimedOut() -> Bool { defaults.bool(forKey: PreferenceKeys.isServiceTimedOut) }

    // MARK: - Helpers
    private func readTempEmail(_ key: String) -> TempEmail {
        guard let data = defaults.data(forKey: key),
              let temp = try? decoder.decode(TempEmail.self, from: data) else {
            return TempEmail(email: "", reservationId: "")
        }
        return temp
    }
    private func writeTempEmail(_ temp: TempEmail, _ key: String) {
        if let data = try? encoder.encode(temp) { defaults.set(data, forKey: key) }
    }
}
