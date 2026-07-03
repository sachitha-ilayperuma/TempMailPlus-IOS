import SwiftUI

/// Ported from Android `presentation/MainActivity.kt`'s top-level `NavHost` gating: shows a
/// loading indicator while `isFirstLaunch` is unresolved, then routes to `OnboardingView`
/// (first launch) or `MainScaffold`. `EmailDetailScreen`/`FAQScreen` are Android nav-graph
/// destinations reachable from within `MainScaffold` in this port (Inbox → detail via
/// `fullScreenCover`, drawer → FAQ via `fullScreenCover`) rather than separate top-level
/// routes — SwiftUI has no need for a single shared `NavHost` the way Compose Navigation
/// does.
///
/// Android's `SplashScreen.kt` composable is dead code (never wired into any nav route —
/// confirmed via grep; only the native Android 12 system splash API is used). The iOS
/// analog of that native system splash is the `UILaunchScreen` in Info.plist — no custom
/// splash view is ported here to match.
struct RootView: View {
    @EnvironmentObject private var container: AppContainer
    @ObservedObject var viewModel: HomeViewModel

    // Android transitions off Onboarding via an explicit `navController.navigate(...)` call
    // from the "Finish" button — not by `isFirstLaunch` (itself a one-shot, non-reactive
    // fetch on both platforms) changing and re-rendering. This session-local flag is the
    // SwiftUI equivalent of that one-way navigation action, decoupled from
    // `viewModel.isFirstLaunch`'s stale one-shot value.
    @State private var onboardingComplete = false

    var body: some View {
        Group {
            if let isFirstLaunch = viewModel.isFirstLaunch {
                if isFirstLaunch && !onboardingComplete {
                    OnboardingView(onFinish: finishOnboarding)
                } else {
                    MainScaffold(viewModel: viewModel)
                }
            } else {
                ZStack {
                    AppColors.background.ignoresSafeArea()
                    ProgressView().tint(AppColors.themeBlue)
                }
            }
        }
    }

    /// Ported from Android's `navigateToHome` (called from `OnboardingScreen.kt`): seeds
    /// `lastInappReviewTimestamp` to "29 days 22 hours ago" so the native review prompt's
    /// 30-day cooldown doesn't fire immediately for brand-new users, then completes
    /// onboarding.
    private func finishOnboarding() {
        let onboardReviewOffset = (30 * 24 * 60 * 60 * 1000) - (2 * 60 * 1000) // 30 days - 2 hours
        let offsetTime = currentTimeMillis() - onboardReviewOffset
        viewModel.setLastInappReviewTimestamp(offsetTime)
        viewModel.completeOnboarding()
        onboardingComplete = true
    }
}
