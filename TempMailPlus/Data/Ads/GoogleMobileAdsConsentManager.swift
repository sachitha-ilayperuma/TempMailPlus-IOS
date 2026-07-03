import UIKit
import UserMessagingPlatform

/// Ported from Android `data/ads/GoogleMobileAdsConsentManager.kt`.
/// Wraps the UMP SDK's `UMPConsentInformation` for GDPR-impacted consent gathering.
/// (Firebase Analytics event logging on consent status, present in Android, is deferred
/// to Phase 7 alongside the rest of analytics.)
final class GoogleMobileAdsConsentManager {
    typealias ConsentGatheringComplete = (Error?) -> Void

    private let consentInformation = ConsentInformation.shared

    var canRequestAds: Bool { consentInformation.canRequestAds }

    var isPrivacyOptionsRequired: Bool {
        consentInformation.privacyOptionsRequirementStatus == .required
    }

    /// Requests consent info and loads/shows a consent form if required. Should be called
    /// on every app launch, matching Android.
    func gatherConsent(from viewController: UIViewController, completion: @escaping ConsentGatheringComplete) {
        let debugSettings = DebugSettings()
        debugSettings.testDeviceIdentifiers = [Constants.testDeviceHashedID]
        // debugSettings.geography = .EEA // uncomment to force a debug geography for testing

        let parameters = RequestParameters()
        parameters.debugSettings = debugSettings

        consentInformation.requestConsentInfoUpdate(with: parameters) { error in
            if let error {
                completion(error)
                return
            }
            ConsentForm.loadAndPresentIfRequired(from: viewController) { formError in
                completion(formError)
            }
        }
    }

    func showPrivacyOptionsForm(from viewController: UIViewController, completion: @escaping ConsentGatheringComplete) {
        ConsentForm.presentPrivacyOptionsForm(from: viewController) { error in
            completion(error)
        }
    }
}
