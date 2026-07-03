import UIKit
import GoogleMobileAds

/// Ported from Android `data/ads/AppOpenAdManager.kt`.
///
/// NOTE: matching Android — where `viewModel.showAppOpenAd(activity)` is present but
/// commented out at both call sites in `MainScaffold.kt` — this manager is ported for
/// parity but is **not wired to any trigger** in this port either. Preloading/showing an
/// app-open ad on foreground is dormant in the source app, not just in this port.
final class AppOpenAdManager: NSObject {
    private var appOpenAd: AppOpenAd?
    private var isLoadingAd = false
    private var isShowingAd = false
    private var loadTime: Date?

    private static let adValidityDuration: TimeInterval = 4 * 60 * 60 // 4 hours

    private var isAdAvailable: Bool {
        guard appOpenAd != nil, let loadTime else { return false }
        return Date().timeIntervalSince(loadTime) < Self.adValidityDuration
    }

    func loadAd() {
        if isLoadingAd || isAdAvailable { return }
        isLoadingAd = true

        AppOpenAd.load(with: Constants.admobAppOpenID, request: Request()) { [weak self] ad, error in
            guard let self else { return }
            self.isLoadingAd = false
            if error != nil { return }
            self.appOpenAd = ad
            self.loadTime = Date()
            ad?.fullScreenContentDelegate = self
        }
    }

    func showAdIfAvailable(from viewController: UIViewController?, onDismiss: (() -> Void)? = nil) {
        guard !isShowingAd else { return }

        if isAdAvailable, let viewController {
            isShowingAd = true
            pendingDismiss = onDismiss
            appOpenAd?.present(from: viewController)
        } else {
            loadAd()
            onDismiss?()
        }
    }

    private var pendingDismiss: (() -> Void)?
}

extension AppOpenAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        appOpenAd = nil
        isShowingAd = false
        loadAd()
        pendingDismiss?()
        pendingDismiss = nil
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        appOpenAd = nil
        isShowingAd = false
        loadAd()
        pendingDismiss?()
        pendingDismiss = nil
    }
}
