import Foundation
import StoreKit
import Combine

/// Ported from Android `data/datasources/billing/BillingDataSource.kt`, using StoreKit 2
/// instead of Google Play Billing. Mirrors the same responsibilities:
///   - Load product/pricing info for `BillingProducts.all` → `SubscriptionInfo`, persisted
///     via `DataStoreManager.saveSubscriptions` (Android's `queryProducts`).
///   - Check current entitlements on demand (Android's `queryActiveSubscriptions`).
///   - Listen for real-time transaction updates (Android's `PurchasesUpdatedListener` /
///     `onPurchasesUpdated`) via `Transaction.updates`.
///   - Launch a purchase and finish (acknowledge) the transaction on success (Android's
///     `launchSubscriptionPurchase` + `acknowledgePurchase`).
///
/// StoreKit 2 has no "billing client connection" step (Android's `BillingClient.startConnection`
/// + reconnect-with-backoff) — `Product.products(for:)` and the transaction APIs are always
/// available, so that machinery has no iOS equivalent and is intentionally not ported.
final class StoreKitBillingDataSource {
    private let dataStore: DataStoreManager
    private let statusSubject: CurrentValueSubject<SubscriptionStatus, Never>

    var subscriptionStatus: AnyPublisher<SubscriptionStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }

    private var updatesTask: Task<Void, Never>?

    init(dataStore: DataStoreManager) {
        self.dataStore = dataStore
        self.statusSubject = CurrentValueSubject(SubscriptionStatus(isSubscribed: dataStore.isSubscribed()))

        startTransactionListener()
        Task {
            await queryProducts()
            await queryActiveSubscriptions()
        }
    }

    deinit { updatesTask?.cancel() }

    // MARK: - Transaction listener (Android: PurchasesUpdatedListener)

    private func startTransactionListener() {
        updatesTask = Task.detached { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return } // unverified: ignore
        if transaction.revocationDate == nil {
            await transaction.finish()
            updateSubscriptionState(
                isSubscribed: true,
                productId: transaction.productID,
                expirationDate: transaction.expirationDate
            )
        } else {
            await queryActiveSubscriptions()
        }
    }

    // MARK: - Product catalog (Android: queryProducts)

    func queryProducts() async {
        guard let products = try? await Product.products(for: BillingProducts.all) else { return }

        let infos: [SubscriptionInfo] = products.compactMap { product in
            guard let subscription = product.subscription else { return nil }

            let freeTrial: String? = subscription.introductoryOffer.flatMap { offer in
                offer.paymentMode == .freeTrial ? Self.formatPeriod(offer.period) : nil
            }

            return SubscriptionInfo(
                productId: product.id,
                title: product.displayName,
                price: product.displayPrice,
                currencyCode: product.priceFormatStyle.currencyCode,
                freeTrialPeriod: freeTrial,
                billingPeriod: Self.formatPeriod(subscription.subscriptionPeriod),
                description: product.description
            )
        }
        dataStore.saveSubscriptions(infos)
    }

    /// Mirrors Android's `formatBillingPeriod` (period digit + unit → "N day(s)/week(s)/…").
    private static func formatPeriod(_ period: Product.SubscriptionPeriod) -> String {
        let n = period.value
        switch period.unit {
        case .day:   return n == 1 ? "1 day" : "\(n) days"
        case .week:  return n == 1 ? "1 week" : "\(n) weeks"
        case .month: return n == 1 ? "1 month" : "\(n) months"
        case .year:  return n == 1 ? "1 year" : "\(n) years"
        @unknown default: return "\(n)"
        }
    }

    // MARK: - Entitlement check (Android: queryActiveSubscriptions)

    func queryActiveSubscriptions() async {
        var active: Transaction?
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  BillingProducts.all.contains(transaction.productID),
                  transaction.revocationDate == nil
            else { continue }
            active = transaction
            break
        }

        if let active {
            updateSubscriptionState(isSubscribed: true, productId: active.productID, expirationDate: active.expirationDate)
        } else {
            updateSubscriptionState(isSubscribed: false, productId: nil, expirationDate: nil)
        }
    }

    // MARK: - Purchase (Android: launchSubscriptionPurchase)

    func launchSubscriptionPurchase(productId: String) async {
        guard let products = try? await Product.products(for: [productId]), let product = products.first else { return }
        guard let result = try? await product.purchase() else { return }

        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { return }
            await transaction.finish()
            updateSubscriptionState(isSubscribed: true, productId: transaction.productID, expirationDate: transaction.expirationDate)
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }

    // MARK: - State

    private func updateSubscriptionState(isSubscribed: Bool, productId: String?, expirationDate: Date?) {
        dataStore.setSubscribed(isSubscribed)
        let status = SubscriptionStatus(
            isSubscribed: isSubscribed,
            productId: productId,
            expiryTime: expirationDate.map { Int($0.timeIntervalSince1970 * 1000) }
        )
        statusSubject.send(status)
    }
}
