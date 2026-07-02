import SwiftUI

/// Left navigation drawer scaffold, ported from Android
/// `presentation/screen/main/DrawerContent.kt`. Phase 2 wires the dark-mode toggle
/// (functional); the remaining rows (FAQ, Help Center, Blog, Rate us, Try our Web,
/// Support Us, Privacy, Terms) are placeholders completed in Phase 7.
struct AppDrawer: View {
    @EnvironmentObject private var theme: ThemeManager
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColors.themeBlue)
                Text("TempMailPlus")
                    .font(AppFont.pacifico(size: 24))
                    .foregroundStyle(AppColors.themeBlue)
            }
            .padding(.top, 60)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

            Divider()

            // Dark mode toggle (functional)
            Toggle(isOn: Binding(
                get: { theme.isDarkMode },
                set: { _ in theme.toggleDarkMode() }
            )) {
                Label(String(localized: "dark_mode"), systemImage: "moon.fill")
                    .font(.labelSmall)
                    .foregroundStyle(AppColors.onBackground)
            }
            .tint(AppColors.themeBlue)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider()

            // Placeholder rows (Phase 7)
            ForEach(placeholderItems, id: \.0) { item in
                HStack(spacing: 14) {
                    Image(systemName: item.1)
                        .frame(width: 24)
                        .foregroundStyle(AppColors.textSecondary)
                    Text(item.0)
                        .font(.labelSmall)
                        .foregroundStyle(AppColors.onBackground)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.background.ignoresSafeArea())
    }

    private var placeholderItems: [(String, String)] {
        [
            ("FAQ", "questionmark.circle"),
            ("Help Center", "lifepreserver"),
            ("Blog", "doc.text"),
            ("Rate us", "star"),
            ("Try our Web", "globe"),
            ("Support Us", "heart"),
            ("Privacy Policy", "lock.shield"),
            ("Terms & Conditions", "doc.plaintext")
        ]
    }
}
