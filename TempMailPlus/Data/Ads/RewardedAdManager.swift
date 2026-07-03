import UIKit
import GoogleMobileAds

/// Ported from Android `data/ads/RewardedAdManager.kt`.
/// Loads/shows a rewarded interstitial gating free-tier actions (refresh, .com switch,
/// custom email creation).
final class RewardedAdManager: NSObject {
    private var rewardedAd: RewardedAd?
    private var isLoading = false
    private var isRewardGranted = false

    func loadAd(onAdLoaded: (() -> Void)? = nil, onAdFailed: ((Error) -> Void)? = nil) {
        if isLoading || rewardedAd != nil { return }
        isLoading = true

        RewardedAd.load(with: Constants.admobRewardID, request: Request()) { [weak self] ad, error in
            guard let self else { return }
            self.isLoading = false
            if let error {
                self.rewardedAd = nil
                onAdFailed?(error)
                return
            }
            self.rewardedAd = ad
            ad?.fullScreenContentDelegate = self
            onAdLoaded?()
        }
    }

    func showAd(
        from viewController: UIViewController,
        onUserEarnedReward: @escaping () -> Void,
        noAdAvailableYet: @escaping () -> Void
    ) {
        guard let ad = rewardedAd else {
            noAdAvailableYet()
            loadAd()
            return
        }

        isRewardGranted = false
        pendingRewardCallback = onUserEarnedReward
        ad.present(from: viewController) { [weak self] in
            self?.isRewardGranted = true
        }
    }

    private var pendingRewardCallback: (() -> Void)?
}

extension RewardedAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        if isRewardGranted {
            pendingRewardCallback?()
        }
        pendingRewardCallback = nil
        rewardedAd = nil
        loadAd() // preload next one
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        rewardedAd = nil
        pendingRewardCallback = nil
    }
}
