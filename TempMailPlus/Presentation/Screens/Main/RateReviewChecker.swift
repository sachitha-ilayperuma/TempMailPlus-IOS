import SwiftUI
import StoreKit

/// Ported from Android `presentation/screen/main/RateViewController.kt`. Android observes
/// `ON_PAUSE`→`ON_RESUME` lifecycle transitions; the iOS analog is `scenePhase` going
/// `.background`/`.inactive` → `.active`. Cooldowns and the custom-sheet-then-native-review
/// escalation logic are ported exactly.
struct RateReviewChecker: ViewModifier {
    @ObservedObject var viewModel: HomeViewModel
    let onShowCustomInapp: () -> Void
    let onShowAppOpenAd: () -> Void

    var customReviewCooldownMillis: Int = 1 * 60 * 60 * 1000       // 1 hour
    var inappReviewCooldownMillis: Int = 30 * 24 * 60 * 60 * 1000  // 30 days

    @Environment(\.scenePhase) private var scenePhase
    @State private var hasShownRate = false
    @State private var wasBackgrounded = false

    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) { newPhase in
                switch newPhase {
                case .background, .inactive:
                    wasBackgrounded = true
                case .active:
                    if wasBackgrounded { checkAndShow() }
                    wasBackgrounded = false
                @unknown default:
                    break
                }
            }
    }

    private func checkAndShow() {
        // Ported from Android's outer `RateReviewChecker` gate (`MainScaffold.kt`): if the
        // user already reviewed or explicitly clicked "later" — in this session or any
        // prior one — the whole flow stays inactive. Checked fresh each time rather than
        // once at mount (Android's `shouldShow` is a one-time LaunchedEffect check), but
        // since nothing else can flip these flags mid-session, the observable behavior is
        // identical while being simpler than replicating the one-time-gate mechanism.
        guard !viewModel.isReviewed(), !viewModel.isClickedReviewLater() else { return }

        let now = currentTimeMillis()
        if !hasShownRate {
            let lastShown = viewModel.lastCustomReviewTimestamp()
            if (now - lastShown) > customReviewCooldownMillis {
                onShowCustomInapp()
                hasShownRate = true
                viewModel.setLastCustomReviewTimestamp(now)
            }
        } else {
            let lastShown = viewModel.lastInappReviewTimestamp()
            if (now - lastShown) > inappReviewCooldownMillis {
                requestNativeReview()
                hasShownRate = true
                viewModel.setLastInappReviewTimestamp(now)
            } else {
                onShowAppOpenAd()
            }
        }
    }

    /// iOS analog of Android's Play In-App Review API.
    private func requestNativeReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
}

extension View {
    func rateReviewChecker(
        viewModel: HomeViewModel,
        onShowCustomInapp: @escaping () -> Void,
        onShowAppOpenAd: @escaping () -> Void = {}
    ) -> some View {
        modifier(RateReviewChecker(viewModel: viewModel, onShowCustomInapp: onShowCustomInapp, onShowAppOpenAd: onShowAppOpenAd))
    }
}

/// Opens the App Store listing directly (Android's `reviewApp` fallback that deep-links to
/// the Play Store listing when in-app review isn't available). Used by the custom rate
/// sheet's "Rate Now" button.
func openAppStoreListing() {
    // NOTE: replace with the real App Store id once the app is published (see
    // PROGRESS.md Phase 7 open items).
    guard let url = URL(string: "https://apps.apple.com/app/id0000000000?action=write-review") else { return }
    UIApplication.shared.open(url)
}
