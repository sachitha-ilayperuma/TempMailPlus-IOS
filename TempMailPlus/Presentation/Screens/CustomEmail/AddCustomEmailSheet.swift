import SwiftUI

/// Ported from Android `presentation/screen/addCustomEmail/AddCustomEmailBottomSheet.kt`.
/// The domain `DropdownMenu` becomes a native SwiftUI `Menu`.
struct AddCustomEmailSheet: View {
    let domainsList: [String]
    let isSubscribed: Bool
    let activeEmailsList: [TempEmail]
    let canRequestAds: Bool
    let onDismiss: () -> Void
    let onAddCustomEmail: (String, String, Int) -> Void
    let onShowSubscriptionView: () -> Void

    @StateObject private var viewModel: CustomEmailViewModel
    @State private var username = ""
    @State private var selectedDomain = ""
    @FocusState private var fieldFocused: Bool

    init(
        domainsList: [String],
        isSubscribed: Bool,
        activeEmailsList: [TempEmail],
        canRequestAds: Bool,
        viewModel: @autoclosure @escaping () -> CustomEmailViewModel,
        onDismiss: @escaping () -> Void,
        onAddCustomEmail: @escaping (String, String, Int) -> Void,
        onShowSubscriptionView: @escaping () -> Void
    ) {
        self.domainsList = domainsList
        self.isSubscribed = isSubscribed
        self.activeEmailsList = activeEmailsList
        self.canRequestAds = canRequestAds
        self._viewModel = StateObject(wrappedValue: viewModel())
        self.onDismiss = onDismiss
        self.onAddCustomEmail = onAddCustomEmail
        self.onShowSubscriptionView = onShowSubscriptionView
    }

    private var hasUsername: Bool { !username.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 16)

                Text(String(localized: "create_custom_email"))
                    .font(AppFont.raleway(.medium, size: 20))
                    .foregroundStyle(AppColors.onBackground)
                    .frame(maxWidth: .infinity)

                Spacer().frame(height: 24)

                HStack(spacing: 6) {
                    TextField(String(localized: "your_email"), text: $username)
                        .focused($fieldFocused)
                        .font(AppFont.raleway(.medium, size: 14))
                        .foregroundStyle(AppColors.onBackground)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(.horizontal, 12)
                        .frame(height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.uiState.errorMessage?.isEmpty == false ? AppColors.red : AppColors.onBackground, lineWidth: 1)
                        )

                    Text("@")
                        .font(.labelMedium)
                        .foregroundStyle(AppColors.onBackground)

                    Menu {
                        ForEach(domainsList, id: \.self) { domain in
                            Button(domain) { selectedDomain = domain }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedDomain)
                                .font(.labelMedium)
                                .foregroundStyle(AppColors.onBackground)
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundStyle(AppColors.onBackground.opacity(0.7))
                        }
                        .padding(.horizontal, 12)
                        .frame(minWidth: 100, minHeight: 50)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.onBackground, lineWidth: 1))
                    }
                }

                Spacer().frame(height: 28)

                Button {
                    fieldFocused = false
                    viewModel.logCustomEmailClicked(isSubscribed: isSubscribed)
                    if !isSubscribed {
                        viewModel.handleLockedUserCustomEmail(canCreateForLockedUser: viewModel.uiState.canCreateForLockedUser)
                    } else {
                        viewModel.createCustomEmail(prefix: username, domain: selectedDomain)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(viewModel.uiState.isProcessing ? String(localized: "processing") : String(localized: "text_continue"))
                            .font(.labelMedium)
                            .foregroundStyle(hasUsername ? AppColors.white : AppColors.black)
                        if !isSubscribed && !viewModel.uiState.canCreateForLockedUser {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(hasUsername ? AppColors.darkYellow : AppColors.onBackground)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(hasUsername ? AppColors.themeBlue : AppColors.lightAsh, in: RoundedRectangle(cornerRadius: 10))
                }
                .disabled(!hasUsername)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)

            if let error = viewModel.uiState.errorMessage, !error.isEmpty {
                Text(error)
                    .font(.labelMedium)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(AppColors.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 6)
                    .transition(.opacity)
                    .task(id: error) {
                        try? await Task.sleep(nanoseconds: 1_400_000_000)
                        viewModel.updateErrorMessage(nil)
                    }
            }
        }
        .onAppear {
            if selectedDomain.isEmpty { selectedDomain = domainsList.first ?? "" }
            viewModel.refreshCanCreateForLockedUser(activeEmails: activeEmailsList)
        }
        .onChange(of: domainsList) { newList in
            if selectedDomain.isEmpty { selectedDomain = newList.first ?? "" }
        }
        .onChange(of: activeEmailsList) { list in
            viewModel.refreshCanCreateForLockedUser(activeEmails: list)
        }
        .onChange(of: viewModel.uiState.showSubscriptionDialog) { show in
            if show {
                onShowSubscriptionView()
                viewModel.resetShowSubscriptionDialog()
            }
        }
        .onChange(of: viewModel.uiState.selectedEmail) { email in
            if let email {
                onAddCustomEmail(email, viewModel.uiState.reservationID ?? "", viewModel.uiState.expiresAt ?? 0)
                onDismiss()
                viewModel.resetCustomEmailState()
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.uiState.showRewardedAdConfirmPopup },
            set: { if !$0 { viewModel.resetRewardedAdPopup() } }
        )) {
            WatchAdBottomSheet(
                title: String(localized: "watch_ad_title"),
                description: String(localized: "watch_ad_desc"),
                onWatchAd: {
                    viewModel.showRewardAd(
                        from: UIKitBridge.rootViewController,
                        canRequestAds: canRequestAds,
                        prefix: username,
                        domain: selectedDomain
                    )
                },
                onSubscriptionClicked: {
                    viewModel.resetRewardedAdPopup()
                    onShowSubscriptionView()
                }
            )
        }
        .presentationDetents([.height(320)])
    }
}
