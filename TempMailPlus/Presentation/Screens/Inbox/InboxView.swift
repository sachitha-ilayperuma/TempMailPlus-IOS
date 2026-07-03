import SwiftUI

private struct EmailID: Identifiable { let id: String }

/// Ported from Android `presentation/screen/inbox/InboxScreen.kt` (InboxScreenNew).
///
/// NOTE (verified against the Android source, not "fixed"): the expired-state refresh
/// here always shows the watch-ad sheet, and tapping "watch ad" always regenerates the
/// email directly **without invoking the real ad SDK at all** — unlike Home's equivalent
/// flow, which does call the real rewarded ad. Android's `InboxScreen.kt` wires
/// `onAdCountdownFinished = { generateNewEmail(false) }` unconditionally, with no
/// `isSubscribed` or `canRequestAds` check. This is a genuine inconsistency in the source
/// app (ported faithfully, see PROGRESS.md Phase 5).
struct InboxView: View {
    @ObservedObject var viewModel: HomeViewModel
    var onShowSubscription: () -> Void = {}
    @EnvironmentObject private var container: AppContainer

    @State private var dropdownExpanded = false
    @State private var selected: EmailID?
    @State private var showCountdownAdSheet = false

    private var s: HomeUiState { viewModel.uiState }
    private var currentEmail: String? { s.tempEmail?.email }
    private var sortedEmails: [Email] { s.emails.sorted { $0.receivedAt > $1.receivedAt } }
    private var showDropdown: Bool { s.activeEmailsList.count > 1 }

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                if s.isExpired {
                    ConnectionLost(isSubscribed: s.isSubscribed) {
                        showCountdownAdSheet = true
                    }
                } else {
                    EmailDropdownHeader(
                        selectedEmail: currentEmail ?? String(localized: "no_email"),
                        expanded: dropdownExpanded,
                        shouldShowDropdown: showDropdown,
                        onTap: { if showDropdown { dropdownExpanded.toggle() } }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    if sortedEmails.isEmpty && !s.isLoading {
                        EmptyInboxView { reload() }
                    } else if !sortedEmails.isEmpty {
                        List {
                            ForEach(sortedEmails) { email in
                                EmailItem(email: email)
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    .contentShape(Rectangle())
                                    .onTapGesture { selected = EmailID(id: email.id) }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .refreshable { reload() }
                    }
                }
            }

            if dropdownExpanded && showDropdown {
                dropdownOverlay
            }

            if sortedEmails.isEmpty && s.isLoading && !s.isExpired {
                ProgressView().tint(AppColors.themeBlue)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear { viewModel.clearNewEmailFlag() }
        .fullScreenCover(item: $selected) { item in
            EmailDetailView(emailId: item.id, viewModel: container.makeEmailDetailViewModel())
        }
        .sheet(isPresented: $showCountdownAdSheet) {
            WatchAdBottomSheet(
                title: String(localized: "watch_ad_title"),
                description: String(localized: "watch_ad_desc"),
                onWatchAd: {
                    // Faithful to Android: no real ad call here, see the type-level note above.
                    viewModel.generateNewEmail(loadComEmail: false)
                    showCountdownAdSheet = false
                },
                onSubscriptionClicked: {
                    showCountdownAdSheet = false
                    onShowSubscription()
                }
            )
        }
    }

    private func reload() {
        if let currentEmail { viewModel.loadEmails(currentEmail) }
    }

    // MARK: - Dropdown overlay (normal + custom sections)
    private var dropdownOverlay: some View {
        ZStack(alignment: .top) {
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture { dropdownExpanded = false }

            let normals = s.activeEmailsList.filter { !$0.isCustomEmail }
            let customs = s.activeEmailsList.filter { $0.isCustomEmail }

            VStack(spacing: 0) {
                ForEach(normals, id: \.email) { item in
                    dropdownRow(item)
                    if item.email != normals.last?.email { Divider() }
                }
                if !customs.isEmpty {
                    Text("Custom Emails")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(AppColors.onBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(AppColors.surface)
                    ForEach(customs, id: \.email) { item in
                        dropdownRow(item)
                        if item.email != customs.last?.email { Divider() }
                    }
                }
            }
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.onBackground.opacity(0.15), lineWidth: 1))
            .shadow(radius: 6)
            .padding(.horizontal, 16)
            .offset(y: 60)
        }
    }

    private func dropdownRow(_ item: TempEmail) -> some View {
        let isSelected = item.email == currentEmail
        return HStack(spacing: 8) {
            Image(systemName: "envelope.fill")
                .foregroundStyle(isSelected ? AppColors.themeBlue : AppColors.textSecondary)
            Text(item.email)
                .font(.labelMedium)
                .foregroundStyle(AppColors.onBackground)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? AppColors.lightBlue : AppColors.surface)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.setSelectedEmailFromDropdown(item)
            dropdownExpanded = false
        }
    }
}

// MARK: - Dropdown header (ported from EmailDropdownHeader.kt)
private struct EmailDropdownHeader: View {
    let selectedEmail: String
    let expanded: Bool
    let shouldShowDropdown: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "envelope.fill").foregroundStyle(AppColors.themeBlue)
                Text(selectedEmail)
                    .font(.labelMedium)
                    .foregroundStyle(AppColors.onBackground)
                    .lineLimit(1)
                Spacer()
                if shouldShowDropdown {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(AppColors.lightBlue)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.onBackground.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty inbox (ported from EmptyInboxView)
private struct EmptyInboxView: View {
    let onRefresh: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: "envelope.open")
                .font(.system(size: 44))
                .foregroundStyle(AppColors.themeBlue)
                .frame(width: 120, height: 120)
                .background(AppColors.surfaceDim(colorScheme), in: Circle())

            Spacer().frame(height: 30)

            Text(String(localized: "inbox_is_empty"))
                .font(.titleLarge)
                .foregroundStyle(AppColors.onBackground)
                .padding(.bottom, 8)
            Text(String(localized: "waiting_for_new_emails"))
                .font(.labelMedium)
                .foregroundStyle(AppColors.onBackground)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 30)

            Button(action: onRefresh) {
                Text(String(localized: "refresh"))
                    .font(.titleLarge)
                    .foregroundStyle(AppColors.themeBlue)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(AppColors.surfaceDim(colorScheme), in: RoundedRectangle(cornerRadius: 12))
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Email row (ported from EmailItem)
private struct EmailItem: View {
    let email: Email
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Text(email.from)
                    .font(.headlineMedium)
                    .foregroundStyle(AppColors.onBackground)
                    .lineLimit(1)
                Spacer()
                Text(Self.time(email.receivedAt))
                    .font(.labelSmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
            HStack(spacing: 0) {
                Text("Subject : ").font(.labelMedium).foregroundStyle(AppColors.onBackground)
                Text(email.subject).font(.labelMedium).foregroundStyle(AppColors.onBackground).lineLimit(1)
            }
            Text(email.body.strippedHTML)
                .font(.labelSmall)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surfaceDim(colorScheme), in: RoundedRectangle(cornerRadius: 12))
    }

    private static func time(_ millis: Int) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return f.string(from: Date(timeIntervalSince1970: Double(millis) / 1000.0))
    }
}
