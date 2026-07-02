import Foundation

/// Ported from Android `core/time/TimeProvider.kt`. Provides server-synced "now" in
/// epoch millis by applying the persisted device→server offset.
final class TimeProvider {
    private let timeRepository: TimeRepository

    init(timeRepository: TimeRepository) {
        self.timeRepository = timeRepository
    }

    func now() async -> Int {
        await timeRepository.getCurrentServerTimeMillis()
    }
}
