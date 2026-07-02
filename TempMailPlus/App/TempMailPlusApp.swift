import SwiftUI

@main
struct TempMailPlusApp: App {
    @StateObject private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootShellView()
                .environmentObject(container)
                .environmentObject(container.themeManager)
        }
    }
}
