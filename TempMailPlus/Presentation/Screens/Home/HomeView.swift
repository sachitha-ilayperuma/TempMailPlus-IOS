import SwiftUI

/// Ported from Android `presentation/screen/home/HomeScreen.kt` (HomeScreenContent), now
/// including real ad-gating (Phase 5). Subscription sheet is still a Phase 6 hook. Branded
/// logo/icons use SF Symbols as stand-ins for the Android drawables.
struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    var onOpenCustomEmail: () -> Void = {}
    var onOpenSubscription: () -> Void = {}          // Phase 6

    @State private var confirmationAction: ConfirmationAction?
    @State private var copied = false
    @State private var showStandardAdSheet = false
    @State private var showComMailAdSheet = false

    private var s: HomeUiState { viewModel.uiState }
    private var isCustomEmail: Bool { s.tempEmail?.isCustomEmail ?? false }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // "Try .com" banner button, top-trailing
                HStack {
                    Spacer()
                    Button { confirmationAction = .loadComMail } label: {
                        Text(String(localized: "try_dot_com"))
                            .font(.labelSmall)
                            .foregroundStyle(AppColors.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppColors.darkYellow, in: Capsule())
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 5)
                }

                ScrollView {
                    VStack(spacing: 0) {
                        Text(String(localized: s.isSubscribed ? "home_title_subscribed" : "home_title"))
                            .font(AppFont.raleway(.bold, size: 28))
                            .foregroundStyle(AppColors.themeBlue)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 10)

                        logo

                        Spacer().frame(height: 8)

                        emailPill

                        Text(labelText)
                            .font(.labelMedium)
                            .foregroundStyle(labelColor)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                            .padding(.bottom, 24)

                        if !s.isExpired {
                            actionButtons
                        } else {
                            expiredRefreshButton
                        }
                    }
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)
                }

                if s.canRequestAds && !s.isSubscribed {
                    BannerAdView()
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                }
            }

            if s.isLoading {
                ProgressView()
                    .tint(AppColors.themeBlue)
            }
        }
        .sheet(item: $confirmationAction) { action in
            let cfg = action.config(isSubscribed: s.isSubscribed)
            ConfirmSheet(
                config: cfg,
                onFailed: { confirmationAction = nil },
                onSuccess: {
                    handleConfirm(action)
                    confirmationAction = nil
                }
            )
        }
        .sheet(isPresented: Binding(
            get: { showStandardAdSheet || showComMailAdSheet },
            set: { if !$0 { showStandardAdSheet = false; showComMailAdSheet = false } }
        )) {
            WatchAdBottomSheet(
                title: String(localized: "watch_ad_title"),
                description: String(localized: "watch_ad_desc"),
                onWatchAd: {
                    // Capture which flow this is before resetting, matching Android.
                    let isComMail = showComMailAdSheet
                    showStandardAdSheet = false
                    showComMailAdSheet = false
                    showRewardedAd(isComEmail: isComMail)
                },
                onSubscriptionClicked: {
                    showStandardAdSheet = false
                    showComMailAdSheet = false
                    onOpenSubscription()
                }
            )
        }
        // Ported from Android's HomeScreen.kt LaunchedEffect(Unit): request notification
        // permission on first appearance, unless the user already declined.
        .onAppear {
            viewModel.requestNotificationPermissionIfNeeded()
        }
    }

    // MARK: - Pieces

    private var logo: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "envelope.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 84, height: 84)
                .foregroundStyle(s.isExpired ? AppColors.red : AppColors.themeBlue)
                .frame(width: 120, height: 120)

            if s.newEmailFlag {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColors.red)
            }
        }
    }

    private var emailPill: some View {
        ZStack {
            HStack(spacing: 4) {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(emailText)
                        .font(.titleLarge)
                        .foregroundStyle(s.isExpired ? AppColors.red : AppColors.onBackground)
                        .lineLimit(1)
                        .padding(.leading, s.isExpired ? 0 : 20)
                }
                .frame(maxWidth: .infinity, alignment: s.isExpired ? .center : .leading)

                if !s.isExpired {
                    Button {
                        if let email = s.tempEmail?.email {
                            UIPasteboard.general.string = email
                            withAnimation { copied = true }
                        }
                    } label: {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(AppColors.white)
                            .frame(width: 42, height: 42)
                            .background(AppColors.themeBlue, in: Circle())
                    }
                    .padding(4)
                    .accessibilityLabel(String(localized: "copy_email"))
                }
            }
            .frame(height: 50)
            .overlay(
                Capsule().stroke(s.isExpired ? .clear : AppColors.onBackground, lineWidth: 1)
            )

            if copied {
                Text(String(localized: "copied"))
                    .font(.labelMedium)
                    .foregroundStyle(AppColors.white)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Color.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
                    .transition(.opacity)
                    .task(id: copied) {
                        guard copied else { return }
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        withAnimation { copied = false }
                    }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Button { confirmationAction = .resetMailbox } label: {
                    Label(String(localized: "refresh"), systemImage: "arrow.clockwise")
                        .font(.labelMedium)
                        .foregroundStyle(AppColors.onBackground)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.onBackground, lineWidth: 1))
                }

                if !isCustomEmail {
                    Button { confirmationAction = .deleteEmail } label: {
                        Label(String(localized: "delete"), systemImage: "trash")
                            .font(.labelMedium)
                            .foregroundStyle(AppColors.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(AppColors.red, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }

            Button(action: onOpenCustomEmail) {
                Label(String(localized: "btn_custom_email"), systemImage: "pencil")
                    .font(.labelMedium)
                    .foregroundStyle(AppColors.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(AppColors.themeBlue, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var expiredRefreshButton: some View {
        Button {
            if s.isSubscribed { viewModel.generateNewEmail(loadComEmail: false) }
            else { showStandardAdSheet = true }
        } label: {
            Text(String(localized: "refresh"))
                .font(.titleMedium)
                .foregroundStyle(AppColors.themeBlue)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(AppColors.surfaceDim(colorScheme), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Derived text

    @Environment(\.colorScheme) private var colorScheme

    private var emailText: String {
        if s.isExpired { return String(localized: "connection_lost") }
        return s.tempEmail?.email ?? String(localized: "loading")
    }

    private var labelText: String {
        if s.isExpired {
            return String(localized: s.isSubscribed ? "text_offline_subscribed" : "text_offline")
        }
        return String(localized: isCustomEmail ? "desc_custom_email" : "your_temp_email")
    }

    private var labelColor: Color {
        if s.isExpired { return AppColors.red }
        return isCustomEmail ? AppColors.onBackground : AppColors.textSecondary
    }

    // MARK: - Actions (Phase 5: real ad gating)

    private func handleConfirm(_ action: ConfirmationAction) {
        switch action {
        case .deleteEmail, .resetMailbox:
            if s.isSubscribed { viewModel.generateNewEmail(loadComEmail: false) }
            else { showStandardAdSheet = true }
        case .loadComMail:
            if s.isSubscribed { viewModel.generateNewEmail(loadComEmail: true) }
            else { showComMailAdSheet = true }
        }
    }

    /// Ported exactly from Android's `showRewardedAd` closure: **both** the reward-earned
    /// and no-ad-available-yet callbacks generate the email (Android's own fail-open
    /// design — gating happens by requiring the sheet tap, not by the ad completion
    /// signal). Not "fixed" here; ported faithfully.
    private func showRewardedAd(isComEmail: Bool) {
        guard s.canRequestAds, let vc = UIKitBridge.rootViewController else {
            viewModel.generateNewEmail(loadComEmail: false)
            return
        }
        viewModel.showRewardAd(
            from: vc,
            onReward: { viewModel.generateNewEmail(loadComEmail: isComEmail) },
            noAdAvailableYet: { viewModel.generateNewEmail(loadComEmail: isComEmail) }
        )
    }
}
