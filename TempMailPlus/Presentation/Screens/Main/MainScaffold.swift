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
    @State private var showPremium = false
    @State private var showCustomEmail = false

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
                            onOpenCustomEmail: { showCustomEmail = true },
                            onOpenSubscription: { showPremium = true }
                        )
                    case .inbox:
                        InboxView(viewModel: viewModel, onShowSubscription: { showPremium = true })
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
                    isPrivacyOptionsRequired: viewModel.uiState.isPrivacyOptionsRequired,
                    onShowPrivacyOptionsForm: {
                        if let vc = UIKitBridge.rootViewController {
                            viewModel.showPrivacyOptionsForm(from: vc) { _ in }
                        }
                    },
                    onClose: closeDrawer
                )
                    .frame(width: 300)
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: drawerOpen)
        .preferredColorScheme(theme.colorScheme)
        .sheet(isPresented: $showPremium) {
            SubscriptionSheet(
                viewModel: container.makeSubscriptionViewModel(),
                onDismiss: { showPremium = false }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showCustomEmail) {
            AddCustomEmailSheet(
                domainsList: viewModel.uiState.domains,
                isSubscribed: viewModel.uiState.isSubscribed,
                activeEmailsList: viewModel.uiState.activeEmailsList,
                canRequestAds: viewModel.uiState.canRequestAds,
                viewModel: container.makeCustomEmailViewModel(),
                onDismiss: { showCustomEmail = false },
                onAddCustomEmail: { email, reservationID, expiresAt in
                    viewModel.updateCustomEmail(email: email, reservationID: reservationID, expiresAt: expiresAt)
                },
                onShowSubscriptionView: {
                    showCustomEmail = false
                    showPremium = true
                }
            )
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
        Button { showPremium = true } label: {
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
