import Foundation

/// Ported from Android `data/repository/OnboardRepositoryImpl.kt`.
final class OnboardRepositoryImpl: OnboardRepository {
    private let dataStore: DataStoreManager

    init(dataStore: DataStoreManager) {
        self.dataStore = dataStore
    }

    func isFirstLaunch() async -> Bool { dataStore.isFirstLaunch() }
    func setFirstLaunch(_ isFirst: Bool) async { dataStore.setFirstLaunch(isFirst) }
}
