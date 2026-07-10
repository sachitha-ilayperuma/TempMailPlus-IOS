import SwiftUI

/// Ported from Android `presentation/screen/faq/FAQScreen.kt`. A single expanded item at a
/// time (Android's `expandedIndex` int, not a Set) — matched exactly.
struct FAQView: View {
    let onBackClick: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var expandedIndex: Int? = nil

    // NSLocalizedString takes a plain runtime String key, unlike String(localized:) whose
    // string-interpolation initializer treats interpolated segments as format arguments,
    // not part of the lookup key — the wrong tool for a genuinely dynamic key like "faq\(i)".
    private var faqList: [(String, String)] {
        (1...11).map { i in
            (NSLocalizedString("faq\(i)", comment: ""), NSLocalizedString("faqa\(i)", comment: ""))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider()

            List {
                ForEach(Array(faqList.enumerated()), id: \.offset) { index, faq in
                    FAQRow(
                        question: faq.0,
                        answer: faq.1,
                        expanded: expandedIndex == index,
                        onTap: {
                            withAnimation { expandedIndex = expandedIndex == index ? nil : index }
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .background(AppColors.background.ignoresSafeArea())
    }

    private var topBar: some View {
        ZStack {
            Text(String(localized: "faq"))
                .font(.headlineMedium)
                .foregroundStyle(AppColors.onBackground)
            HStack {
                Button(action: onBackClick) {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.onBackground)
                }
                .accessibilityLabel("Back")
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 52)
        .frame(maxWidth: .infinity)
        .background(AppColors.surface)
    }
}

private struct FAQRow: View {
    let question: String
    let answer: String
    let expanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack(alignment: .center) {
                    Text(question)
                        .font(.titleMedium)
                        .foregroundStyle(AppColors.onBackground)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(AppColors.onBackground)
                }
            }
            .buttonStyle(.plain)

            if expanded {
                Text(answer)
                    .font(.labelMedium)
                    .foregroundStyle(AppColors.onBackground)
                    .padding(.top, 10)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}
