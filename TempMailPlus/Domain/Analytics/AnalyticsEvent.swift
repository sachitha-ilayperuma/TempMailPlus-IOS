import Foundation

/// Ported from Android `domain/analytics/AnalyticsEvent.kt`. Event names/param keys match
/// exactly so any downstream Firebase dashboards built against the Android app's event
/// schema keep working unchanged for iOS.
enum AnalyticsEvent {
    case subscriptionSuccess(formattedPrice: String)
    case clickSupportUs
    case clickTryOurBlog
    case clickTryOurWeb
    case clickRateNow
    case clickSubscriptionActivate
    case clickCustomEmail(isPremium: Bool)

    var name: String {
        switch self {
        case .subscriptionSuccess:      return "subscription_success"
        case .clickSupportUs:           return "click_support_us"
        case .clickTryOurBlog:          return "click_try_our_blog"
        case .clickTryOurWeb:           return "click_try_our_web"
        case .clickRateNow:             return "click_rate_now"
        case .clickSubscriptionActivate: return "click_subscription_activate"
        case .clickCustomEmail:         return "click_custom_email"
        }
    }

    var params: [String: Any] {
        switch self {
        case .subscriptionSuccess(let price): return ["price": price]
        case .clickCustomEmail(let isPremium): return ["is_premium_user": isPremium]
        default: return [:]
        }
    }
}
