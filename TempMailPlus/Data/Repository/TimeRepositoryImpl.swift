import Foundation

/// Ported from Android `data/repository/TimeRepositoryImpl.kt`.
final class TimeRepositoryImpl: TimeRepository {
    private let api: EmailApi
    private let dataStore: DataStoreManager

    init(api: EmailApi, dataStore: DataStoreManager) {
        self.api = api
        self.dataStore = dataStore
    }

    func syncServerTime() async -> Resource<Int> {
        do {
            let serverTime = try await api.getCurrentTimestamp()
            let offset = serverTime - currentTimeMillis()
            dataStore.saveServerTimeOffset(offset)
            return .success(serverTime)
        } catch {
            return .failure(error)
        }
    }

    func getCurrentServerTimeMillis() async -> Int {
        currentTimeMillis() + dataStore.getServerTimeOffset()
    }
}
