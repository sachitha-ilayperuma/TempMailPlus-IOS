import Foundation

// Mirrors the Android `core/Constants.kt`.
//
// NOTE: AdMob unit IDs are platform-specific — the Android IDs cannot be reused on
// iOS. These are Google's official *test* IDs and MUST be replaced with the real iOS
// ad units before release (tracked in IMPLEMENTATION_PLAN.md §5 / §8, wired in Phase 5).
enum Constants {
    // Google sample/test ad unit IDs (iOS).
    static let admobBannerID  = "ca-app-pub-3940256099942544/2934735716"
    static let admobRewardID  = "ca-app-pub-3940256099942544/1712485313"
    static let admobAppOpenID = "ca-app-pub-3940256099942544/5575463023"

    static let adTag = "AD_TAG"
}
