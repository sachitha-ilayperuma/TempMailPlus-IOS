import Foundation

// Ported from Android `domain/model/SubscriptionStatus.kt`.
struct SubscriptionStatus: Equatable {
    let isSubscribed: Bool
    var productId: String? = nil
    var expiryTime: Int? = nil
}
