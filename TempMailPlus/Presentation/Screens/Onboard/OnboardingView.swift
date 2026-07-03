import SwiftUI

/// Ported from Android `presentation/screen/onboard/OnboardingScreen.kt`. Uses the real
/// onboarding artwork converted from the Android app's WebP/JPEG drawables (see
/// PROGRESS.md Phase 7) — full-bleed pager pages with a bottom gradient overlay, page
/// indicator dots, and Skip/Previous/Next/Finish controls.
struct OnboardingView: View {
    let onFinish: () -> Void

    private let images = ["OnboardImage1", "OnboardImage2", "OnboardImage3", "OnboardImage4", "OnboardImage5"]
    @State private var currentPage = 0

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $currentPage) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, name in
                    Image(name)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .ignoresSafeArea()
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button("Skip") { finish() }
                        .foregroundStyle(.gray)
                        .padding()
                }
                Spacer()

                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        ForEach(0..<images.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.white : Color.gray)
                                .frame(width: 10, height: 10)
                        }
                    }

                    HStack(spacing: 16) {
                        if currentPage > 0 {
                            Button {
                                withAnimation { currentPage -= 1 }
                            } label: {
                                Text("Previous")
                                    .font(.system(size: 18))
                                    .foregroundStyle(AppColors.themeBlue)
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.themeBlue, lineWidth: 1))
                            }
                        } else {
                            Spacer()
                        }

                        Button {
                            if currentPage < images.count - 1 {
                                withAnimation { currentPage += 1 }
                            } else {
                                finish()
                            }
                        } label: {
                            Text(currentPage == images.count - 1 ? "Finish" : "Next")
                                .font(.system(size: 18))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .padding(.top, 16)
                .background(
                    LinearGradient(
                        colors: [Color(white: 0.11).opacity(0), Color(white: 0.11), Color(white: 0.11)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            }
        }
        .background(Color(white: 0.11).ignoresSafeArea())
    }

    /// Purely presentational — `onFinish` (supplied by the root view, which owns
    /// `HomeViewModel`) performs Android's `navigateToHome` logic: seeding
    /// `lastInappReviewTimestamp` and completing onboarding. See `RootView.swift`.
    private func finish() {
        onFinish()
    }
}
