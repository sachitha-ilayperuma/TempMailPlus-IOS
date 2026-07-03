import XCTest
import Combine
@testable import TempMailPlus

// MARK: - Fake

/// A fake `BillingRepository` — tests `SubscriptionViewModel`'s own logic (plan
/// selection, purchase triggering, status observation) without touching real StoreKit,
/// which `xcodebuild test` cannot exercise from the command line (Xcode scheme
/// StoreKit-configuration files are an Xcode-GUI-only mechanism; see
/// PROGRESS.md Phase 6 for the real, manually-verifiable StoreKit 2 integration test).
private final class FakeBillingRepository: BillingRepository {
    let statusSubject = CurrentValueSubject<TempMailPlus.SubscriptionStatus, Never>(
        TempMailPlus.SubscriptionStatus(isSubscribed: false)
    )
    private(set) var purchaseCalls: [String] = []
    private(set) var refreshCallCount = 0

    func getSubscriptionStatus() -> AnyPublisher<TempMailPlus.SubscriptionStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }

    func refreshSubscriptionStatus() async {
        refreshCallCount += 1
    }

    func startSubscriptionPurchase(productId: String) async {
        purchaseCalls.append(productId)
        statusSubject.send(TempMailPlus.SubscriptionStatus(isSubscribed: true, productId: productId))
    }
}

@MainActor
final class SubscriptionViewModelTests: XCTestCase {
    private var defaults: UserDefaults!
    private var dataStore: DataStoreManager!
    private var repo: FakeBillingRepository!
    private var viewModel: SubscriptionViewModel!
    private let suite = "TempMailPlusTests.SubscriptionVM"

    private let weekly = SubscriptionInfo(
        productId: BillingProducts.weeklyV1, title: "Weekly", price: "$1.99",
        currencyCode: "USD", freeTrialPeriod: "3 days", billingPeriod: "1 week", description: ""
    )
    private let monthly = SubscriptionInfo(
        productId: BillingProducts.monthlyV1, title: "Monthly", price: "$4.99",
        currencyCode: "USD", freeTrialPeriod: nil, billingPeriod: "1 month", description: ""
    )
    private let yearly = SubscriptionInfo(
        productId: BillingProducts.yearlyV1, title: "Yearly", price: "$39.99",
        currencyCode: "USD", freeTrialPeriod: "1 week", billingPeriod: "1 year", description: ""
    )

    private var analytics: FakeAnalyticsTracker!

    override func setUp() {
        super.setUp()
        let d = UserDefaults(suiteName: suite)!
        d.removePersistentDomain(forName: suite)
        defaults = d
        dataStore = DataStoreManager(defaults: d)
        repo = FakeBillingRepository()
        analytics = FakeAnalyticsTracker()
        viewModel = SubscriptionViewModel(billingRepository: repo, dataStore: dataStore, analyticsTracker: analytics)
    }

    /// `DataStoreManager.subscriptionsSubject` is piped through `.receive(on: RunLoop.main)`
    /// in `SubscriptionViewModel` (matching production's deferred-to-main-run-loop delivery,
    /// same as `HomeViewModel`), so `sink` fires on the next run loop pass, not synchronously
    /// with `send()`. Tests yield briefly before asserting.
    private func yieldToRunLoop() async {
        try? await Task.sleep(nanoseconds: 20_000_000)
    }

    func test_plansUpdate_filtersToActiveProductsOnly() async {
        let legacy = SubscriptionInfo(
            productId: BillingProducts.weekly, title: "Legacy", price: "$0.99",
            currencyCode: "USD", freeTrialPeriod: nil, billingPeriod: "1 week", description: ""
        )
        dataStore.saveSubscriptions([weekly, monthly, yearly, legacy])
        await yieldToRunLoop()

        XCTAssertEqual(Set(viewModel.uiState.plans.map(\.productId)), Set(BillingProducts.activeProducts))
        XCTAssertFalse(viewModel.uiState.isLoading)
    }

    func test_plansUpdate_autoSelectsYearlyPlan() async {
        dataStore.saveSubscriptions([weekly, monthly, yearly])
        await yieldToRunLoop()
        XCTAssertEqual(viewModel.uiState.selectedPlan?.productId, BillingProducts.yearlyV1)
    }

    func test_plansUpdate_alwaysReselectsYearly_evenAfterManualSelection() async {
        // Ported exactly from Android: every plan-list update re-selects yearly,
        // regardless of a prior manual selection (not gated on selectedPlan == nil).
        dataStore.saveSubscriptions([weekly, monthly, yearly])
        await yieldToRunLoop()
        viewModel.onPlanSelected(weekly)
        XCTAssertEqual(viewModel.uiState.selectedPlan?.productId, BillingProducts.weeklyV1)

        dataStore.saveSubscriptions([weekly, monthly, yearly]) // re-emit
        await yieldToRunLoop()
        XCTAssertEqual(viewModel.uiState.selectedPlan?.productId, BillingProducts.yearlyV1)
    }

    func test_onPlanSelected_updatesSelection() {
        dataStore.saveSubscriptions([weekly, monthly, yearly])
        viewModel.onPlanSelected(monthly)
        XCTAssertEqual(viewModel.uiState.selectedPlan?.productId, BillingProducts.monthlyV1)
    }

    func test_startPurchase_withNoSelectedPlan_doesNothing() {
        viewModel.startPurchase()
        XCTAssertTrue(repo.purchaseCalls.isEmpty)
    }

    func test_startPurchase_callsRepositoryWithSelectedProduct() async {
        dataStore.saveSubscriptions([weekly, monthly, yearly])
        viewModel.onPlanSelected(monthly)
        viewModel.startPurchase()

        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(repo.purchaseCalls, [BillingProducts.monthlyV1])
    }

    func test_subscriptionStatus_reflectsRepositoryUpdates() async {
        XCTAssertFalse(viewModel.uiState.isSubscribed)
        repo.statusSubject.send(TempMailPlus.SubscriptionStatus(isSubscribed: true))
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertTrue(viewModel.uiState.isSubscribed)
    }

    func test_refreshStatus_callsRepository() async {
        viewModel.refreshStatus()
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(repo.refreshCallCount, 1)
    }

    func test_startPurchase_logsClickSubscriptionActivate_evenWithNoSelection() {
        // Ported exactly from Android: the event fires before the selectedPlan guard.
        viewModel.startPurchase()
        XCTAssertEqual(analytics.loggedEvents.count, 1)
        guard case .clickSubscriptionActivate = analytics.loggedEvents[0] else {
            return XCTFail("expected .clickSubscriptionActivate event")
        }
    }
}
