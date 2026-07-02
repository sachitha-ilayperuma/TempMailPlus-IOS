import Foundation
import UIKit

/// Ported from Android `data/repository/DeviceIdProviderImpl.kt`.
/// iOS analog of ANDROID_ID is `identifierForVendor`; falls back to a random UUID.
/// The id is generated once and persisted, so it survives even if `identifierForVendor`
/// later changes (e.g. after all vendor apps are uninstalled).
final class DeviceIdProviderImpl: DeviceIdProvider {
    private let dataStore: DataStoreManager

    init(dataStore: DataStoreManager) {
        self.dataStore = dataStore
    }

    func getDeviceId() async -> String {
        if let cached = dataStore.getDeviceIdOrNil(), !cached.isEmpty {
            return cached
        }
        let vendorId = await MainActor.run { UIDevice.current.identifierForVendor?.uuidString }
        let finalId = (vendorId?.isEmpty == false ? vendorId! : UUID().uuidString)
        dataStore.saveDeviceId(finalId)
        return finalId
    }
}
