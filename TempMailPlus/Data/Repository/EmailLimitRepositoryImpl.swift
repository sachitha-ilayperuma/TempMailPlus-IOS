import Foundation

/// Ported from Android `data/repository/EmailLimitRepositoryImpl.kt`.
final class EmailLimitRepositoryImpl: EmailLimitRepository {
    private let api: EmailApi
    private let dataStore: DataStoreManager

    init(api: EmailApi, dataStore: DataStoreManager) {
        self.api = api
        self.dataStore = dataStore
    }

    func getServerTimestamp() async -> Resource<Int> {
        do {
            return .success(try await api.getCurrentTimestamp())
        } catch {
            return .failure(error)
        }
    }

    func getDailyEmailCount() async -> Int { dataStore.getDailyEmailCount() }
    func getDailyEmailDay() async -> String { dataStore.getDailyEmailDate() }
    func updateDailyUsage(count: Int, lastDate: String) async {
        dataStore.updateDailyEmailCount(count: count, lastDate: lastDate)
    }
}
