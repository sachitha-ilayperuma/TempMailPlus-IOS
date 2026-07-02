import Foundation

// Ported from Android `domain/model/SubscriptionInfo.kt`.
struct SubscriptionInfo: Codable, Equatable {
    let productId: String
    let title: String
    let price: String
    let currencyCode: String
    let freeTrialPeriod: String?
    let billingPeriod: String
    let description: String
}
