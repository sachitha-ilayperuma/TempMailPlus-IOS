import SwiftUI

/// Placeholder for the Inbox tab. The real inbox (list, address dropdown, swipe-to-delete,
/// empty/waiting states, live updates) is built in Phase 3.
struct InboxPlaceholderView: View {
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "tray")
                    .font(.system(size: 48))
                    .foregroundStyle(AppColors.textSecondary)
                Text(String(localized: "inbox"))
                    .font(.titleLarge)
                    .foregroundStyle(AppColors.onBackground)
                Text("Coming in Phase 3")
                    .font(.labelSmall)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}
