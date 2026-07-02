import SwiftUI

// Ported from the Android `presentation/theme/AppTypography.kt`.
// PostScript names verified against the bundled .ttf files via CoreText.
//
// Sizes are anchored to a Dynamic Type text style via `relativeTo:` so they scale
// with the user's system font-size setting — matching Android's `.sp` behavior and
// keeping the app accessible.
enum AppFont {
    static func raleway(
        _ weight: Font.Weight = .regular,
        size: CGFloat,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        let name: String
        switch weight {
        case .medium:              name = "Raleway-Medium"
        case .semibold:            name = "Raleway-SemiBold"
        case .bold:                name = "Raleway-Bold"
        case .heavy, .black:       name = "Raleway-ExtraBold"
        default:                   name = "Raleway-Regular"
        }
        return .custom(name, size: size, relativeTo: textStyle)
    }

    /// Brand/logo script font (Compose `CustomFontFamily`).
    static func pacifico(size: CGFloat, relativeTo textStyle: Font.TextStyle = .largeTitle) -> Font {
        .custom("Pacifico-Regular", size: size, relativeTo: textStyle)
    }
}

// Compose Material3 `Typography` ramp used across the app.
extension Font {
    static let headlineMedium = AppFont.raleway(.semibold, size: 20, relativeTo: .title3)
    static let titleLarge     = AppFont.raleway(.bold, size: 18, relativeTo: .headline)
    static let titleMedium    = AppFont.raleway(.semibold, size: 16, relativeTo: .body)
    static let labelMedium    = AppFont.raleway(.medium, size: 18, relativeTo: .body)
    static let labelSmall     = AppFont.raleway(.medium, size: 16, relativeTo: .subheadline)
}
