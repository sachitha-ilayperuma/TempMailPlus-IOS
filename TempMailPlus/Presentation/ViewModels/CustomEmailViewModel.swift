import UIKit

/// Ported from Android `presentation/viewModel/CustomEmailViewModel.kt`.
/// Ad-gating for free users uses the real `RewardedAdManager` (Phase 5).
struct CustomEmailUiState {
    var isProcessing = false
    var errorMessage: String?
    var successMessage: String?
    var selectedEmail: String?
    var reservationID: String?
    var expiresAt: Int?
    var canCreateForLockedUser = false
    var showRewardedAdConfirmPopup = false
    var showSubscriptionDialog = false
}

@MainActor
final class CustomEmailViewModel: ObservableObject {
    @Published private(set) var uiState = CustomEmailUiState()

    private let createCustomEmailUseCase: CreateCustomEmailUseCase
    private let validateUsernameUseCase: ValidateUsernameUseCase
    private let dataStore: DataStoreManager
    private let timeProvider: TimeProvider
    private let rewardedAdManager: RewardedAdManager

    init(
        createCustomEmailUseCase: CreateCustomEmailUseCase,
        validateUsernameUseCase: ValidateUsernameUseCase,
        dataStore: DataStoreManager,
        timeProvider: TimeProvider,
        rewardedAdManager: RewardedAdManager
    ) {
        self.createCustomEmailUseCase = createCustomEmailUseCase
        self.validateUsernameUseCase = validateUsernameUseCase
        self.dataStore = dataStore
        self.timeProvider = timeProvider
        self.rewardedAdManager = rewardedAdManager
    }

    func createCustomEmail(prefix: String, domain: String) {
        uiState.isProcessing = true

        let result = validateUsernameUseCase(prefix)
        if !result.isValid {
            uiState.errorMessage = result.errorMessage
            uiState.isProcessing = false
            return
        }

        Task {
            do {
                let response = try await createCustomEmailUseCase(prefix: prefix, domain: domain)
                if response.code == "SUCCESS", let email = response.email, let reservationId = response.reservationId {
                    uiState.isProcessing = false
                    uiState.successMessage = response.message
                    uiState.selectedEmail = email
                    uiState.reservationID = reservationId
                    uiState.expiresAt = response.expiresAt
                    uiState.errorMessage = nil
                } else {
                    uiState.isProcessing = false
                    uiState.errorMessage = response.error ?? "Unknown error"
                }
            } catch let error as CustomEmailError {
                uiState.isProcessing = false
                uiState.errorMessage = Self.message(for: error)
            } catch {
                uiState.isProcessing = false
                uiState.errorMessage = error.localizedDescription
            }
        }
    }

    private static func message(for error: CustomEmailError) -> String {
        switch error {
        case .activeSessionExists: return String(localized: "error_email_limit_reached")
        case .missingParameters:   return String(localized: "error_missing_parameters")
        case .unknown:             return String(localized: "error_generic")
        }
    }

    func handleLockedUserCustomEmail(canCreateForLockedUser: Bool) {
        uiState.showRewardedAdConfirmPopup = canCreateForLockedUser
        uiState.showSubscriptionDialog = !canCreateForLockedUser
    }

    func refreshCanCreateForLockedUser(activeEmails: [TempEmail]) {
        let freeExpired = dataStore.getFreeCustomEmailExpiredTimestamp() == 0
        let hasCustomEmail = activeEmails.contains { $0.isCustomEmail }
        uiState.canCreateForLockedUser = freeExpired && !hasCustomEmail
    }

    /// Ported from Android `showRewardAd(activity, canRequestAds, prefix, domain)`: shows the
    /// real rewarded ad; on reward, creates the email and stamps the 25h free-usage window.
    /// Falls back to the subscription dialog if ads can't be requested.
    func showRewardAd(from viewController: UIViewController?, canRequestAds: Bool, prefix: String, domain: String) {
        guard let viewController, canRequestAds else {
            showSubscription()
            return
        }
        rewardedAdManager.showAd(
            from: viewController,
            onUserEarnedReward: { [weak self] in
                self?.createCustomEmail(prefix: prefix, domain: domain)
                self?.updateFreeEmailExpiredTimestamp()
                self?.resetRewardedAdPopup()
            },
            noAdAvailableYet: { [weak self] in
                self?.showSubscription()
            }
        )
    }

    func updateFreeEmailExpiredTimestamp() {
        Task {
            let expiry = await timeProvider.now() + (25 * 60 * 60 * 1000) // 25 hours
            dataStore.saveFreeCustomEmailExpiredTimestamp(expiry)
        }
    }

    func showSubscription() {
        uiState.showRewardedAdConfirmPopup = false
        uiState.showSubscriptionDialog = true
    }

    func updateErrorMessage(_ message: String?) {
        uiState.errorMessage = message
    }

    /// Matches Android exactly: only these four fields reset. `reservationID`/`expiresAt`/
    /// `canCreateForLockedUser`/the popup flags are intentionally left as-is (ported as-is,
    /// not "fixed", to preserve identical behavior).
    func resetCustomEmailState() {
        uiState.isProcessing = false
        uiState.errorMessage = nil
        uiState.successMessage = nil
        uiState.selectedEmail = nil
    }

    func resetShowSubscriptionDialog() {
        uiState.showSubscriptionDialog = false
    }

    func resetRewardedAdPopup() {
        uiState.showRewardedAdConfirmPopup = false
    }

    /// Stub — Android logs `AnalyticsEvent.ClickCustomEmail` here via Firebase.
    /// Analytics wiring is Phase 7.
    func logCustomEmailClicked(isSubscribed: Bool) {}
}
