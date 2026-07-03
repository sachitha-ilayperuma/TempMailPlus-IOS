import SwiftUI

/// Ported from Android `presentation/components/WatchAdBottomSheet.kt`.
/// The "Watch ad" button is UI-complete; the actual rewarded-ad SDK call is stubbed
/// until Phase 5 (see call sites — they create the email/email directly on tap).
struct WatchAdBottomSheet: View {
    let title: String
    let description: String
    let onWatchAd: () -> Void
    var onSubscriptionClicked: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 8) {
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 10)

            Text(title)
                .font(.headlineMedium)
                .foregroundStyle(AppColors.onBackground)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Text(description)
                .font(.labelSmall)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20)

            Button(action: onWatchAd) {
                Text(String(localized: "watch_ad"))
                    .font(.headlineMedium)
                    .foregroundStyle(AppColors.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(AppColors.themeBlue, in: Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)

            HStack(spacing: 8) {
                Text(String(localized: "or"))
                    .font(.headlineMedium)
                    .foregroundStyle(AppColors.textSecondary)
                Button {
                    onSubscriptionClicked?()
                } label: {
                    Text(String(localized: "unlock_premium_access"))
                        .font(.headlineMedium)
                        .foregroundStyle(AppColors.themeBlue)
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 10)
        .presentationDetents([.height(300)])
    }
}
