import SwiftUI

/// Ported from Android `presentation/screen/premium/SubscriptionScreen.kt`.
/// Uses a crown SF Symbol as a stand-in for the Android Lottie `twincle_crown` animation
/// (the .json is bundled from Phase 0; swapping in a real Lottie render is Phase 7 polish —
/// lottie-ios is a clean SPM add like Phase 5's ad SDKs, just out of scope for this phase).
struct SubscriptionSheet: View {
    @ObservedObject var viewModel: SubscriptionViewModel
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 8)

                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppColors.darkYellow)
                    .frame(width: 90, height: 90)

                Text("Experience More with Premium")
                    .font(.titleMedium)
                    .foregroundStyle(AppColors.onBackground)
                    .multilineTextAlignment(.center)
                    .padding(.trailing, 10)

                Spacer().frame(height: 8)

                PremiumFeaturesList()

                Spacer().frame(height: 16)

                VStack(spacing: 12) {
                    ForEach(viewModel.uiState.plans, id: \.productId) { plan in
                        PlanCard(
                            plan: plan,
                            isSelected: plan == viewModel.uiState.selectedPlan,
                            onTap: { viewModel.onPlanSelected(plan) }
                        )
                    }
                }
                .padding(.horizontal, 16)

                Spacer().frame(height: 20)

                Button {
                    viewModel.startPurchase()
                } label: {
                    Text(viewModel.uiState.isSubscribed ? "Subscribed" : "Activate Plan")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.black)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(
                            viewModel.uiState.selectedPlan != nil ? AppColors.darkYellow : AppColors.lightAsh,
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                }
                .disabled(viewModel.uiState.selectedPlan == nil)
                .padding(.horizontal, 16)
            }
            .padding(16)
        }
        .background(AppColors.surface)
        .clipShape(.rect(topLeadingRadius: 24, topTrailingRadius: 24))
        .overlay(
            UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                .stroke(AppColors.black, lineWidth: 2)
        )
        .onChange(of: viewModel.uiState.isSubscribed) { subscribed in
            if subscribed { onDismiss() }
        }
    }
}

/// Ported from Android `PremiumFeaturesList`.
private struct PremiumFeaturesList: View {
    private var features: [FeatureItem] {
        [
            .simple(String(localized: "subscription_point_1")),
            .simple(String(localized: "subscription_point_2")),
            .strikethrough(
                normal: String(localized: "subscription_point_3"),
                strike: String(localized: "subscription_sub_point_3"),
                normalEnd: ")"
            ),
            .simple(String(localized: "subscription_point_4")),
            .simple(String(localized: "subscription_point_5")),
            .simple(String(localized: "subscription_point_6"))
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(features.enumerated()), id: \.offset) { _, feature in
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.darkYellow)
                    featureText(feature)
                        .font(.labelMedium)
                        .foregroundStyle(AppColors.onBackground)
                }
                .padding(.vertical, 6)
            }
        }
        .padding(.horizontal, 26)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func featureText(_ feature: FeatureItem) -> some View {
        switch feature {
        case .simple(let text):
            Text(text)
        case .strikethrough(let normal, let strike, let normalEnd):
            Text(normal) + Text(strike).strikethrough() + Text(normalEnd)
        }
    }
}

/// Ported from Android `PlanCard`. Note: Android's own `.background(background)` line is
/// commented out in the source — only the border color changes when selected, matching here.
private struct PlanCard: View {
    let plan: SubscriptionInfo
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.titleMedium)
                        .foregroundStyle(AppColors.onBackground)
                    Text("Cancel Anytime")
                        .font(.labelMedium)
                        .foregroundStyle(AppColors.onBackground)
                }
                .padding(.trailing, 10)
                Spacer()
                Text(plan.price)
                    .font(.titleMedium)
                    .foregroundStyle(AppColors.onBackground)
            }
            .padding(16)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppColors.darkYellow : AppColors.lightAsh, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
