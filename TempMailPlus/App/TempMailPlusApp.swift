import SwiftUI

@main
struct TempMailPlusApp: App {
    @StateObject private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            // Phase 7 will add Splash → Onboarding gating in front of this.
            MainScaffold(viewModel: container.homeViewModel)
                .environmentObject(container)
                .environmentObject(container.themeManager)
        }
    }
}
