import SwiftUI

/// Ported from Android `presentation/screen/main/MainScaffold.swift` (top bar + bottom
/// navigation + modal drawer + nav host). Home/Inbox are tabs; Premium opens the real
/// StoreKit 2 subscription flow (Phase 6). App-open/consent/ad init (Phase 5) hooks off
/// `viewModel.isInitCalled`.
struct MainScaffold: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.scenePhase) private var scenePhase

    enum Tab { case home, inbox }
    @State private var tab: Tab = .home
    @State private var drawerOpen = false
    @State private var showFAQ = false

    /// Single source of truth for the three sheet-style modals (Premium, Custom Email,
    /// Rate), presented via one `.sheet(item:)`. Stacking several independent
    /// `.sheet(isPresented:)` modifiers on the same view is a known SwiftUI conflict
    /// source (observed once during Phase 7 verification — see PROGRESS.md); this enum
    /// makes "at most one sheet active" structurally true instead of relying on discipline
    /// across four separate booleans. FAQ stays a separate `.fullScreenCover` since it's a
    /// different presentation style and a single extra modifier carries no such risk.
    private enum ActiveSheet: Identifiable {
        case premium, customEmail, rate
        var id: Int {
            switch self {
            case .premium: return 0
            case .customEmail: return 1
            case .rate: return 2
            }
        }
    }
    @State private var activeSheet: ActiveSheet?

    var body: some View {
        ZStack(alignment: .leading) {
            VStack(spacing: 0) {
                topBar
                Divider()

                ZStack {
                    switch tab {
                    case .home:
                        HomeView(
                            viewModel: viewModel,
                            onOpenCustomEmail: { activeSheet = .customEmail },
                            onOpenSubscription: { activeSheet = .premium }
                        )
                    case .inbox:
                        InboxView(viewModel: viewModel, onShowSubscription: { activeSheet = .premium })
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()
                bottomBar
            }
            .disabled(drawerOpen)

            if drawerOpen {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { closeDrawer() }
                    .transition(.opacity)

                AppDrawer(
                    isDarkMode: theme.isDarkMode,
                    isSubscribed: viewModel.uiState.isSubscribed,
                    isPrivacyOptionsRequired: viewModel.uiState.isPrivacyOptionsRequired,
                    onToggleDarkMode: { theme.toggleDarkMode() },
                    onOpenFAQ: { closeDrawer(); showFAQ = true },
                    onBlogClicked: { viewModel.logFirebaseEvent(.clickTryOurBlog) },
                    onTryOurWebClicked: { viewModel.logFirebaseEvent(.clickTryOurWeb) },
                    onSupportUsClicked: { viewModel.logFirebaseEvent(.clickSupportUs) },
                    onRateUsClicked: { closeDrawer(); activeSheet = .rate },
                    onShowPrivacyOptionsForm: {
                        if let vc = UIKitBridge.rootViewController {
                            viewModel.showPrivacyOptionsForm(from: vc) { _ in }
                        }
                    },
                    onSubscriptionViewClicked: { closeDrawer(); activeSheet = .premium },
                    onClose: closeDrawer
                )
                    .frame(width: 300)
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: drawerOpen)
        .preferredColorScheme(theme.colorScheme)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .premium:
                SubscriptionSheet(
                    viewModel: container.makeSubscriptionViewModel(),
                    onDismiss: { activeSheet = nil }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)

            case .customEmail:
                AddCustomEmailSheet(
                    domainsList: viewModel.uiState.domains,
                    isSubscribed: viewModel.uiState.isSubscribed,
                    activeEmailsList: viewModel.uiState.activeEmailsList,
                    canRequestAds: viewModel.uiState.canRequestAds,
                    viewModel: container.makeCustomEmailViewModel(),
                    onDismiss: { activeSheet = nil },
                    onAddCustomEmail: { email, reservationID, expiresAt in
                        viewModel.updateCustomEmail(email: email, reservationID: reservationID, expiresAt: expiresAt)
                    },
                    onShowSubscriptionView: { activeSheet = .premium }
                )

            case .rate:
                RateAppBottomSheet(
                    onLater: {
                        activeSheet = nil
                        viewModel.setClickedReviewLater(true)
                    },
                    onRateNow: {
                        activeSheet = nil
                        viewModel.setReviewed(true)
                        viewModel.logFirebaseEvent(.clickRateNow)
                        openAppStoreListing()
                    }
                )
                .presentationDetents([.height(460)])
                .presentationDragIndicator(.hidden)
            }
        }
        .fullScreenCover(isPresented: $showFAQ) {
            FAQView(onBackClick: { showFAQ = false })
        }
        // Ported from Android EmailValidityObserver (ON_RESUME): re-check expiry when the
        // app returns to the foreground, since an email may have expired while backgrounded.
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                viewModel.checkAndHandleEmailExpiration()
            }
        }
        // Reactively (re)connect the WebSocket when the selected email changes — ports
        // Android MainScaffold's LaunchedEffect(tempEmail.email) { startWebSocketService }.
        .onChange(of: viewModel.uiState.tempEmail?.email) { email in
            if let email, !email.isEmpty {
                viewModel.startWebSocketService(email: email)
            }
        }
        // Ported from Android's `LaunchedEffect(Unit) { if (!viewModel.isInitCalled) initAdsAndConsent(activity) }`.
        .onAppear {
            if !viewModel.isInitCalled, let vc = UIKitBridge.rootViewController {
                viewModel.initAdsAndConsent(from: vc)
            }
        }
        // Ported from Android's RateReviewChecker/RateViewController: on foreground-return,
        // escalate through the custom rate sheet then the native App Store review prompt,
        // matching Android's custom-sheet-then-in-app-review cooldown logic.
        .rateReviewChecker(
            viewModel: viewModel,
            onShowCustomInapp: { activeSheet = .rate }
        )
    }

    // MARK: - Top bar
    private var topBar: some View {
        ZStack {
            Text("TempMailPlus")
                .font(AppFont.pacifico(size: 22))
                .foregroundStyle(AppColors.themeBlue)

            HStack {
                Button { openDrawer() } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppColors.onBackground)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 52)
        .frame(maxWidth: .infinity)
        .background(AppColors.background)
    }

    // MARK: - Bottom bar
    private var bottomBar: some View {
        HStack {
            navItem(.home, title: String(localized: "home"), icon: "house.fill")
            navItem(.inbox, title: String(localized: "inbox"), icon: "envelope.fill", badge: viewModel.uiState.newEmailFlag)
            if !viewModel.uiState.isSubscribed {
                premiumItem
            }
        }
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .background(AppColors.surface)
    }

    private func navItem(_ target: Tab, title: String, icon: String, badge: Bool = false) -> some View {
        let selected = tab == target
        return Button { tab = target } label: {
            VStack(spacing: 2) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                    if badge {
                        Circle().fill(AppColors.red).frame(width: 8, height: 8).offset(x: 6, y: -2)
                    }
                }
                Text(title).font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(selected ? AppColors.themeBlue : AppColors.onBackground)
            .frame(maxWidth: .infinity)
        }
    }

    private var premiumItem: some View {
        Button { activeSheet = .premium } label: {
            VStack(spacing: 2) {
                Image(systemName: "crown.fill").font(.system(size: 20))
                Text(String(localized: "premium")).font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(AppColors.darkYellow)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Drawer control
    private func openDrawer() { drawerOpen = true }
    private func closeDrawer() { drawerOpen = false }
}
