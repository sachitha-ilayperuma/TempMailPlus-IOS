import SwiftUI

/// Phase 0 deliverable: an empty, themed shell that proves out the app's foundations —
/// bundled fonts (Raleway + Pacifico), color tokens, and the app-controlled light/dark
/// theme. Real screens (Splash → Onboarding → Home/Inbox/Premium) replace this in the
/// subsequent phases per IMPLEMENTATION_PLAN.md.
struct RootShellView: View {
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AppColors.themeBlue)

                // Pacifico brand font
                Text("TempMailPlus")
                    .font(AppFont.pacifico(size: 40))
                    .foregroundStyle(AppColors.themeBlue)

                // Raleway body font
                Text("Instantly generate temporary emails for free")
                    .font(.titleMedium)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                Button(action: theme.toggleDarkMode) {
                    Label(
                        theme.isDarkMode ? "Switch to Light" : "Switch to Dark",
                        systemImage: theme.isDarkMode ? "sun.max.fill" : "moon.fill"
                    )
                    .font(.labelSmall)
                    .foregroundStyle(AppColors.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(AppColors.themeBlue, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(theme.colorScheme)
    }
}

#Preview {
    RootShellView()
        .environmentObject(ThemeManager())
}
