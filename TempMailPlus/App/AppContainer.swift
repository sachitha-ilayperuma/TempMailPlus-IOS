import Foundation

/// Composition root — the iOS replacement for Hilt's DI modules
/// (`NetworkModule`, `DataStoreModule`, `RepoModule`, `AnalyticsModule`, …).
///
/// Dependencies are constructed here and injected into view models via initializers.
/// Phase 0 wires only the `ThemeManager`; each subsequent phase adds its graph:
///   • Phase 1: DataStoreManager, Decryptor, EmailApiService, TimeProvider, repositories
///   • Phase 2: TempEmail use cases + HomeViewModel factory
///   • Phase 3: WebSocketManager
///   • Phase 4: CustomEmail use cases
///   • Phase 5: Ads managers + consent
///   • Phase 6: BillingRepository (StoreKit 2)
///   • Phase 7: AnalyticsTracker
@MainActor
final class AppContainer: ObservableObject {
    let themeManager = ThemeManager()

    // Future dependencies are added as `let` properties and passed into
    // view-model factories below (kept empty in Phase 0).

    init() {}
}
