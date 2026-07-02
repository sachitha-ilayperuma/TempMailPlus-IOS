import Foundation

/// Tri-state async result, ported from Android `domain/util/Result.kt`
/// (`Loading` / `Success` / `Error`).
///
/// Named `Resource` to avoid colliding with Swift's built-in `Result`. Repository
/// methods in this port are `async throws` (the `.loading` phase is represented by the
/// view model setting `isLoading` before the `await`), and `Resource` is used where a
/// view model needs to hold tri-state for the UI.
enum Resource<T> {
    case loading
    case success(T)
    case failure(Error)
}
