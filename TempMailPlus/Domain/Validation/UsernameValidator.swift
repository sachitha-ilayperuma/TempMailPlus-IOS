import Foundation

// Ported from Android `domain/validation/UsernameValidator.kt`.
struct ValidationResult: Equatable {
    let isValid: Bool
    let errorMessage: String?

    init(_ isValid: Bool, _ errorMessage: String? = nil) {
        self.isValid = isValid
        self.errorMessage = errorMessage
    }
}

struct UsernameValidator {
    private static let allowedPattern = "^[a-zA-Z0-9._-]+$"

    func validate(_ username: String, resource: ResourceProvider) -> ValidationResult {
        if username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return ValidationResult(false, resource.string(StringKey.enterName))
        }
        if username.count < 3 {
            return ValidationResult(false, resource.string(StringKey.tooShort))
        }
        if username.count > 15 {
            return ValidationResult(false, resource.string(StringKey.tooLong))
        }
        if username.range(of: Self.allowedPattern, options: .regularExpression) == nil {
            return ValidationResult(false, resource.string(StringKey.invalidCharacters))
        }

        // Check forbidden keywords (substring match, case-insensitive) — matches Android.
        let lower = username.lowercased()
        for keyword in ForbiddenKeywords.list where lower.contains(keyword) {
            return ValidationResult(false, "\(resource.string(StringKey.restrictedName)) \(keyword)")
        }

        return ValidationResult(true)
    }
}
