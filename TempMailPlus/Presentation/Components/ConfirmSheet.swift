import SwiftUI

/// The Home confirmation actions, ported from Android
/// `presentation/screen/home/ConfirmationAction.kt` + the `ConfirmBottomSheet` config.
enum ConfirmationAction: Identifiable {
    case deleteEmail
    case resetMailbox
    case loadComMail

    var id: Int {
        switch self {
        case .deleteEmail: return 0
        case .resetMailbox: return 1
        case .loadComMail: return 2
        }
    }

    func config(isSubscribed: Bool) -> ConfirmationConfig {
        switch self {
        case .deleteEmail:
            return ConfirmationConfig(
                title: String(localized: "are_you_sure"),
                description: String(localized: "delete_email"),
                textBtnFailed: String(localized: "cancel"),
                textBtnSuccess: String(localized: "delete")
            )
        case .resetMailbox:
            return ConfirmationConfig(
                title: String(localized: "reset_mailbox"),
                description: String(localized: "desc_reset_mailbox"),
                textBtnFailed: String(localized: "no"),
                textBtnSuccess: String(localized: "yes")
            )
        case .loadComMail:
            return ConfirmationConfig(
                title: String(localized: "try_dot_com_title"),
                description: String(localized: isSubscribed ? "try_dot_com_desc_subscribed" : "try_dot_com_desc"),
                textBtnFailed: String(localized: "no"),
                textBtnSuccess: String(localized: "proceed")
            )
        }
    }
}

struct ConfirmationConfig {
    let title: String
    let description: String
    let textBtnFailed: String
    let textBtnSuccess: String
}

/// Ported from Android `ConfirmBottomSheet` — title, description, and two actions.
struct ConfirmSheet: View {
    let config: ConfirmationConfig
    let onFailed: () -> Void
    let onSuccess: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 10)

            Text(config.title)
                .font(.titleLarge)
                .foregroundStyle(AppColors.onBackground)
                .multilineTextAlignment(.center)

            Text(config.description)
                .font(.labelSmall)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Button(action: onFailed) {
                    Text(config.textBtnFailed)
                        .font(.labelMedium)
                        .foregroundStyle(AppColors.onBackground)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.onBackground, lineWidth: 1)
                        )
                }
                Button(action: onSuccess) {
                    Text(config.textBtnSuccess)
                        .font(.labelMedium)
                        .foregroundStyle(AppColors.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(AppColors.themeBlue, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.top, 4)
        }
        .padding(24)
        .presentationDetents([.height(260)])
    }
}
