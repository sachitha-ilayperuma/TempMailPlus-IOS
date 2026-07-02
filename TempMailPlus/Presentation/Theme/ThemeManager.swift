import SwiftUI
import Combine

/// Drives light/dark theme from a persisted flag, mirroring the Android
/// `DataStoreManager.getThemeMode()` / `setThemeMode()` behavior (default = light).
///
/// Uses the shared `PreferenceKeys.darkMode` so the key is defined in exactly one place.
/// In Phase 1, once `DataStoreManager` exists, this should read/write through it rather
/// than touching `UserDefaults` directly — see IMPLEMENTATION_PLAN.md Phase 1.
final class ThemeManager: ObservableObject {
    private let defaults: UserDefaults

    @Published var isDarkMode: Bool {
        didSet { defaults.set(isDarkMode, forKey: PreferenceKeys.darkMode) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isDarkMode = defaults.bool(forKey: PreferenceKeys.darkMode) // default false → light
    }

    var colorScheme: ColorScheme { isDarkMode ? .dark : .light }

    func toggleDarkMode() { isDarkMode.toggle() }
}
