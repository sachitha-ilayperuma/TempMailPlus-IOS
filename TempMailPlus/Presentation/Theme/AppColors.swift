import SwiftUI

// Ported 1:1 from the Android `presentation/theme/Color.kt`.
// Values are ARGB (0xAARRGGBB) to match Compose's `Color(0x...)`.
extension Color {
    /// Creates a color from a `0xAARRGGBB` integer, matching Compose's `Color(Long)`
    /// semantics exactly. The top byte is always the alpha channel — every ported
    /// token below is written with an explicit alpha byte (e.g. `0xFF…`, `0x1B…`).
    init(argb: UInt32) {
        let a = Double((argb >> 24) & 0xFF) / 255.0
        let r = Double((argb >> 16) & 0xFF) / 255.0
        let g = Double((argb >> 8) & 0xFF) / 255.0
        let b = Double(argb & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

enum AppColors {
    static let textSecondary      = Color(argb: 0xFF8E8E93)
    static let themeBlue          = Color(argb: 0xFF1C7DDD)
    static let lightBlue          = Color(argb: 0x1B1C7DDD)
    static let lightAsh           = Color(argb: 0x256B6B6B)
    static let red                = Color(argb: 0xFFE03131)
    static let black              = Color(argb: 0xFF000000)
    static let white              = Color(argb: 0xFFFFFFFF)
    static let yellow             = Color(argb: 0xFFFFD400)
    static let darkYellow         = Color(argb: 0xFFEF9600)
    static let darkGray           = Color(argb: 0xFF505050)
    static let lightAshDarkTheme  = Color(argb: 0xFF7C7C7C)
    static let lightBlueDarkTheme = Color(argb: 0x3E1C7DDD)
    static let lightAshBG         = Color(argb: 0xFFF1F1F1)

    // Semantic tokens. Theme is app-controlled (see ThemeManager), so system colors
    // adapt via `.preferredColorScheme`. `surfaceDim` mirrors the Compose color scheme.
    static let background   = Color(uiColor: .systemBackground)
    static let onBackground = Color(uiColor: .label)
    static let surface      = Color(uiColor: .secondarySystemBackground)
    /// Compose `surfaceDim`: LightBlue in light, LightBlueDarkTheme in dark.
    static func surfaceDim(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? lightBlueDarkTheme : lightBlue
    }
}
