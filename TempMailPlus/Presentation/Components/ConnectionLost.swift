import SwiftUI

/// Ported from Android `presentation/components/ConnectionLost.kt`.
/// Shown in the Inbox when the mailbox has expired.
struct ConnectionLost: View {
    let isSubscribed: Bool
    let onRefresh: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: "envelope.fill")
                .resizable().scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(AppColors.red)
                .frame(width: 120, height: 120)

            Spacer().frame(height: 8)

            Text(String(localized: "connection_lost"))
                .font(.titleLarge)
                .foregroundStyle(AppColors.red)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)

            Text(String(localized: isSubscribed ? "text_offline_subscribed" : "text_offline"))
                .font(.labelMedium)
                .foregroundStyle(AppColors.red)
                .multilineTextAlignment(.center)
                .padding(.bottom, 32)

            Button(action: onRefresh) {
                Text(String(localized: "refresh"))
                    .font(.titleMedium)
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
