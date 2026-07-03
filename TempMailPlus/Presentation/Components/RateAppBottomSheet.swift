import SwiftUI

/// Ported from Android `presentation/components/RateAppBottomSheet.kt`. Matches Android's
/// hardcoded (non-localized) copy exactly ("Enjoying the app?", "Later", "Rate Now", …).
struct RateAppBottomSheet: View {
    let onLater: () -> Void
    let onRateNow: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 10)

            Image(systemName: "envelope.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.themeBlue)
                .frame(width: 80, height: 80)
                .padding(.top, 8)

            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(AppColors.yellow)
                }
            }
            .padding(.top, 8)

            Text("Enjoying the app?")
                .font(.labelMedium)
                .foregroundStyle(AppColors.onBackground)
                .padding(.top, 8)

            Text("Your feedback helps us get better. Take a moment to rate us on the App Store!")
                .font(.labelMedium)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            HStack(spacing: 8) {
                Button(action: onLater) {
                    Text("Later")
                        .font(.titleMedium)
                        .foregroundStyle(AppColors.onBackground)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.onBackground, lineWidth: 1))
                }
                Button(action: onRateNow) {
                    Text("Rate Now")
                        .font(.titleMedium)
                        .foregroundStyle(AppColors.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(AppColors.themeBlue, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 8)
    }
}
