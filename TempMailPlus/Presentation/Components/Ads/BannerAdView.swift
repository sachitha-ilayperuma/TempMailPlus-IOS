import SwiftUI
import GoogleMobileAds

/// Ported from Android `presentation/components/ads/BannerAd.kt`. SwiftUI wrapper around
/// `BannerView`, shown at the bottom of Home for free (non-subscribed) users.
struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = Constants.admobBannerID
        banner.rootViewController = UIKitBridge.rootViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
