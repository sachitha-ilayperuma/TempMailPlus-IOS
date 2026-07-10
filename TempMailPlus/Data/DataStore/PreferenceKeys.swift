import Foundation

/// Single source of truth for `UserDefaults` keys — the iOS mirror of the Android
/// `data/datasources/datastore/PreferenceKeys.kt`. String values match Android so the
/// storage contract is identical across platforms.
///
/// In Phase 1 the `DataStoreManager` wrapper owns reads/writes for all of these; until
/// then only `darkMode` is used (by `ThemeManager`). Keeping the key here prevents two
/// components from defining the same string independently and drifting.
enum PreferenceKeys {
    static let darkMode                   = "dark_mode"
    static let hasNewEmail                = "has_new_email"
    static let notiPermissionDeclined     = "noti_permission_declined"
    static let isReviewed                 = "is_reviewed"
    static let isClickedReviewLater       = "clicked_review_later"
    static let isFirstLaunch              = "is_first_launch"
    static let isServiceTimedOut          = "is_service_timed_out"
    static let isSubscribed               = "is_subscribed"
    static let lastInappReviewTimestamp   = "last_inapp_review_timestamp"
    static let lastCustomReviewTimestamp  = "last_custom_review_timestamp"
    static let customEmailCount           = "custom_email_count"
    static let customEmailLastDate        = "custom_email_last_date"
    static let tempEmail                  = "temp_email_json"
    static let normalTempEmail            = "normal_temp_email_json"
    static let pastVersionCustomEmail     = "past_version_custom_email"
    static let selectedTempEmail          = "selected_temp_email_json"
    static let subscriptionInfo           = "subscriptions_json"
    static let deviceId                   = "device_id"
    static let serverTimeOffset           = "server_time_offset"
    static let freeCustomEmailTimestamp   = "free_cu_email_timestamp"
    static let isEmailLoaded              = "is_email_loaded"

    /// iOS-only (Phase 8, no Android source key): tracks email ids already seen by
    /// `BackgroundRefreshManager` so its best-effort background poll only notifies about
    /// genuinely new mail, not the whole inbox on every run.
    static let seenEmailIds               = "seen_email_ids"
}
