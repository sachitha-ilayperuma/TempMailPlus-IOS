import SwiftUI

/// Ported from Android `presentation/screen/emailContent/EmailDetailScreen.kt`.
/// Attachments open in the system browser (iOS analog of Android's DownloadManager).
struct EmailDetailView: View {
    let emailId: String
    @ObservedObject var viewModel: EmailDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var email: Email? { viewModel.uiState.email }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                topBar

                if viewModel.uiState.isLoading {
                    Spacer()
                    ProgressView().tint(AppColors.themeBlue).frame(maxWidth: .infinity)
                    Spacer()
                } else if let email {
                    Text(email.subject)
                        .font(.headlineMedium)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.onBackground)
                        .padding(16)

                    VStack(alignment: .leading, spacing: 0) {
                        senderRow(email)
                        Divider().padding(.vertical, 12)
                        HTMLView(html: email.body)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(AppColors.surfaceDim(colorScheme),
                                in: .rect(topLeadingRadius: 16, topTrailingRadius: 16))
                }
            }

            if let email, !email.attachments.isEmpty {
                AttachmentsBox(attachments: email.attachments)
            }
        }
        .onAppear { viewModel.loadEmail(emailId) }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.onBackground)
                    .padding(8)
                    .background(AppColors.surfaceDim(colorScheme), in: Circle())
            }
            .accessibilityLabel("Back")
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func senderRow(_ email: Email) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text(email.fromName.prefix(1).uppercased())
                .font(.system(size: 25))
                .foregroundStyle(AppColors.onBackground)
                .frame(width: 60, height: 60)
                .background(AppColors.lightBlue, in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(email.fromName).font(.labelMedium).foregroundStyle(AppColors.onBackground)
                Text(email.from).font(.labelSmall).foregroundStyle(AppColors.textSecondary)
                Text(email.receivedAt.formatFullTime()).font(.labelSmall).foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            Text(email.receivedAt.getTimeAgo())
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}

/// Bottom expandable attachments card (ported from AttachmentsBox / ExpandableAttachmentList).
private struct AttachmentsBox: View {
    let attachments: [Attachment]
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button { withAnimation { expanded.toggle() } } label: {
                HStack {
                    Text(String(localized: "attachments"))
                        .font(.headlineMedium).foregroundStyle(AppColors.darkGray)
                    Spacer()
                    Image(systemName: expanded ? "chevron.down" : "chevron.up")
                        .foregroundStyle(AppColors.darkGray)
                }
                .padding(.horizontal, 12).frame(height: 44)
            }
            .buttonStyle(.plain)

            if expanded {
                ForEach(attachments, id: \.url) { attachment in
                    Button { open(attachment) } label: {
                        HStack(spacing: 0) {
                            Image(systemName: "paperclip").foregroundStyle(AppColors.darkGray).padding(12)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(attachment.fileName).font(.labelSmall).foregroundStyle(AppColors.darkGray).lineLimit(1)
                                Text("(\(attachment.size.formatFileSize()))").font(.system(size: 9)).foregroundStyle(AppColors.darkGray)
                            }
                            Spacer()
                            Image(systemName: "arrow.down.circle").foregroundStyle(AppColors.darkGray).padding(12)
                        }
                    }
                    .buttonStyle(.plain)
                    Divider()
                }
            }
        }
        .background(AppColors.white)
        .clipShape(.rect(topLeadingRadius: 16, topTrailingRadius: 16))
        .shadow(radius: 16)
    }

    private func open(_ attachment: Attachment) {
        guard let url = URL(string: attachment.url) else { return }
        UIApplication.shared.open(url)
    }
}
