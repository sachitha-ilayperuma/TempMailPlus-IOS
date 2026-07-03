import SwiftUI

@main
struct TempMailPlusApp: App {
    @StateObject private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: container.homeViewModel)
                .environmentObject(container)
                .environmentObject(container.themeManager)
        }
    }
}
