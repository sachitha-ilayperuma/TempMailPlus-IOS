import Foundation

/// Ported from Android `domain/repository/ResourceProvider.kt`.
/// Resolves localized strings by key (iOS uses `Localizable.strings` keys instead of
/// Android `R.string` int ids).
protocol ResourceProvider {
    func string(_ key: String) -> String
    func string(_ key: String, _ args: CVarArg...) -> String
}

/// String keys mirroring the Android `strings.xml` names used by the domain layer.
enum StringKey {
    static let enterName = "enter_name"
    static let tooShort = "too_short"
    static let tooLong = "too_long"
    static let invalidCharacters = "invalid_characters"
    static let restrictedName = "restricted_name"
}
