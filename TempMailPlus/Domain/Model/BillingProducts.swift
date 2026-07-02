import Foundation

// Ported from Android `domain/model/BillingProducts.kt`.
// NOTE: These IDs must match the App Store Connect subscription product IDs (Phase 6).
enum BillingProducts {
    static let weekly    = "tempmail.weekly_offer"
    static let monthly   = "monthly.premium_offer"

    static let weeklyV1  = "weeklypremium_march2026"
    static let monthlyV1 = "monthly.premium_v2"
    static let yearlyV1  = "annual_permium_v2"

    static let all = [weekly, monthly, weeklyV1, monthlyV1, yearlyV1]
    static let activeProducts = [weeklyV1, monthlyV1, yearlyV1]
}
