import UIKit

/// Google Mobile Ads / UMP APIs need a presenting `UIViewController` — the iOS analog of
/// the `Activity` reference Android's ad managers take. SwiftUI has no first-class handle
/// to "the current view controller", so this resolves it from the active scene's key
/// window, matching the common integration pattern in Google's own sample code.
enum UIKitBridge {
    @MainActor
    static var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
    }
}
