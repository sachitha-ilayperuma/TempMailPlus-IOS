import Foundation
import Combine

/// Ported from Android `data/repository/BillingRepositoryImpl.kt` — a thin delegate to the
/// data source, matching Android exactly (no logic of its own).
final class BillingRepositoryImpl: BillingRepository {
    private let dataSource: StoreKitBillingDataSource

    init(dataSource: StoreKitBillingDataSource) {
        self.dataSource = dataSource
    }

    func getSubscriptionStatus() -> AnyPublisher<SubscriptionStatus, Never> {
        dataSource.subscriptionStatus
    }

    func refreshSubscriptionStatus() async {
        await dataSource.queryActiveSubscriptions()
    }

    func startSubscriptionPurchase(productId: String) async {
        await dataSource.launchSubscriptionPurchase(productId: productId)
    }
}
