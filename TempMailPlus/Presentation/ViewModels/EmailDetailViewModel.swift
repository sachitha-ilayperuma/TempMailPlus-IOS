import Foundation

/// Ported from Android `presentation/viewModel/EmailDetailViewModel.kt`.
/// Resolves the email from the shared repository cache by id.
struct EmailDetailUiState {
    var email: Email?
    var isLoading = false
    var error: String?
}

@MainActor
final class EmailDetailViewModel: ObservableObject {
    @Published private(set) var uiState = EmailDetailUiState()

    private let getEmailByIDUseCase: GetEmailByIDUseCase

    init(getEmailByIDUseCase: GetEmailByIDUseCase) {
        self.getEmailByIDUseCase = getEmailByIDUseCase
    }

    func loadEmail(_ emailId: String) {
        if let email = getEmailByIDUseCase(emailId) {
            uiState.email = email
            uiState.isLoading = false
            uiState.error = nil
        } else {
            uiState.error = "Failed to load email"
        }
    }

    func clearError() {
        uiState.error = nil
    }
}
