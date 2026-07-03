import UIKit

/// Ported from Android `presentation/screen/main/DrawerContent.kt`'s `openLink`.
enum LinkOpener {
    static func open(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}
