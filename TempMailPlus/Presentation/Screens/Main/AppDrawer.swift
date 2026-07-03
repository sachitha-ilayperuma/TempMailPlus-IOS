import SwiftUI

/// Ported from Android `presentation/screen/main/DrawerContent.kt`, in full.
/// Social/menu icons use SF Symbol stand-ins for Android's branded drawables (not copied
/// into the iOS asset catalog) — see PROGRESS.md Phase 7.
struct AppDrawer: View {
    @EnvironmentObject private var theme: ThemeManager
    let isDarkMode: Bool
    let isSubscribed: Bool
    let isPrivacyOptionsRequired: Bool
    let onToggleDarkMode: () -> Void
    let onOpenFAQ: () -> Void
    let onBlogClicked: () -> Void
    let onTryOurWebClicked: () -> Void
    let onSupportUsClicked: () -> Void
    let onRateUsClicked: () -> Void
    let onShowPrivacyOptionsForm: () -> Void
    let onSubscriptionViewClicked: () -> Void
    let onClose: () -> Void

    private var versionName: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                Divider().padding(.vertical, 4)

                Toggle(isOn: Binding(get: { isDarkMode }, set: { _ in onToggleDarkMode() })) {
                    Label(String(localized: "dark_mode"), systemImage: "moon.fill")
                        .font(.labelSmall)
                        .foregroundStyle(AppColors.onBackground)
                }
                .tint(AppColors.themeBlue)

                Divider().padding(.vertical, 4)

                menuItem("faq", "questionmark.circle", action: onOpenFAQ)
                menuItem("help_center", "lifepreserver") {
                    LinkOpener.open("https://temp-emails.net/contact")
                }
                menuItem("blog", "doc.text") {
                    onBlogClicked()
                    LinkOpener.open("https://temp-emails.net/blog")
                }
                menuItem("rate_us", "star", action: onRateUsClicked)

                Divider().padding(.vertical, 4)

                menuItem("try_our_web", "globe") {
                    onTryOurWebClicked()
                    LinkOpener.open("https://temp-emails.net/")
                }
                menuItem("support_us", "heart") {
                    onSupportUsClicked()
                    LinkOpener.open("https://buymeacoffee.com/tempemailplus")
                }

                if isPrivacyOptionsRequired {
                    menuItem("show_privacy_options", "hand.raised.fill", action: onShowPrivacyOptionsForm)
                    Spacer().frame(height: 20)
                }

                if !isSubscribed {
                    subscriptionBanner
                        .padding(.top, 10)
                }

                socialRow
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                footer
            }
            .padding(16)
        }
        .background(AppColors.surface.ignoresSafeArea())
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "envelope.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.themeBlue)
                .frame(width: 80, height: 80)
            Text("Temp Mail Plus")
                .font(.headlineMedium)
                .foregroundStyle(AppColors.themeBlue)
        }
        .frame(maxWidth: .infinity)
    }

    private func menuItem(_ titleKey: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(AppColors.onBackground)
                    .frame(width: 20)
                // NSLocalizedString for a genuinely dynamic runtime key (see FAQView's note
                // on why String(localized:) string-interpolation isn't the right tool here).
                Text(NSLocalizedString(titleKey, comment: ""))
                    .font(.labelSmall)
                    .foregroundStyle(AppColors.onBackground)
                Spacer()
            }
            .padding(.vertical, 15)
        }
        .buttonStyle(.plain)
    }

    private var subscriptionBanner: some View {
        Button(action: onSubscriptionViewClicked) {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "unlock_premium_access"))
                    .font(.labelMedium)
                    .foregroundStyle(AppColors.black)
                Text(String(localized: "go_ad_free"))
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.black)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.darkYellow, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var socialRow: some View {
        HStack {
            socialIcon("play.rectangle.fill") { LinkOpener.open("https://www.youtube.com/watch?v=u7_LIxgtvyA") }
            Spacer()
            socialIcon("music.note") { LinkOpener.open("https://www.tiktok.com/@tempmailplus") }
            Spacer()
            socialIcon("f.square.fill") { LinkOpener.open("https://www.facebook.com/share/1FbbscAL6G/?mibextid=wwXIfr") }
            Spacer()
            socialIcon("at") { LinkOpener.open("https://x.com/Tempemailplus") }
        }
    }

    private func socialIcon(_ systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 22))
                .foregroundStyle(AppColors.onBackground)
                .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        VStack(spacing: 4) {
            HStack {
                Button(String(localized: "privacy_policy")) {
                    LinkOpener.open("https://temp-emails.net/privacy-policy")
                }
                Spacer()
                Button(String(localized: "terms_conditions")) {
                    LinkOpener.open("https://temp-emails.net/privacy-policy")
                }
            }
            .font(.system(size: 12))
            .foregroundStyle(AppColors.textSecondary)
            .padding(.vertical, 8)

            Text("App version \(versionName)")
                .font(.system(size: 12))
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: .infinity)
        }
    }
}
