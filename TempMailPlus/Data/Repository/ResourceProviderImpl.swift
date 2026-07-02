import Foundation

/// Ported from Android `data/repository/ResourceProviderImpl.kt`.
/// Resolves keys from `Localizable.strings`.
final class ResourceProviderImpl: ResourceProvider {
    func string(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    func string(_ key: String, _ args: CVarArg...) -> String {
        String(format: NSLocalizedString(key, comment: ""), arguments: args)
    }
}
