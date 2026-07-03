import Foundation
import Combine

/// Ported from Android `presentation/viewModel/SubscriptionViewModel.kt`.
/// Talks to `BillingRepository` directly (not through use case wrappers) — matching
/// Android exactly. `GetSubscriptionStatusUseCase`/`RefreshSubscriptionUseCase` exist in
/// the Android source but are dead code (never constructed/injected anywhere); this port
/// skips them rather than porting unused wrappers.
struct SubscriptionUiState {
    var isLoading = true
    var isSubscribed = false
    var plans: [SubscriptionInfo] = []
    var selectedPlan: SubscriptionInfo?
    var message: String?
}

@MainActor
final class SubscriptionViewModel: ObservableObject {
    @Published private(set) var uiState = SubscriptionUiState()

    private let billingRepository: BillingRepository
    private var cancellables = Set<AnyCancellable>()

    init(billingRepository: BillingRepository, dataStore: DataStoreManager) {
        self.billingRepository = billingRepository

        billingRepository.getSubscriptionStatus()
            .receive(on: RunLoop.main)
            .sink { [weak self] status in
                self?.uiState.isSubscribed = status.isSubscribed
            }
            .store(in: &cancellables)

        dataStore.subscriptionsSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] plans in
                guard let self else { return }
                let activePlans = plans.filter { BillingProducts.activeProducts.contains($0.productId) }
                self.uiState.isLoading = false
                self.uiState.plans = activePlans

                // Ported exactly from Android: this runs unconditionally whenever the plan
                // list updates (not gated on whether the user already picked a plan) — every
                // refresh re-selects the yearly plan.
                if !activePlans.isEmpty,
                   let yearly = activePlans.first(where: { $0.productId == BillingProducts.yearlyV1 }) {
                    self.onPlanSelected(yearly)
                }
            }
            .store(in: &cancellables)
    }

    func onPlanSelected(_ plan: SubscriptionInfo) {
        uiState.selectedPlan = plan
    }

    func startPurchase() {
        // Analytics: Android logs AnalyticsEvent.ClickSubscriptionActivate here (Phase 7 stub).
        guard let selected = uiState.selectedPlan else { return }
        Task {
            uiState.isLoading = true
            await billingRepository.startSubscriptionPurchase(productId: selected.productId)
            uiState.isLoading = false
        }
    }

    func refreshStatus() {
        Task { await billingRepository.refreshSubscriptionStatus() }
    }
}
