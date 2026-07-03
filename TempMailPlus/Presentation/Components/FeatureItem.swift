import Foundation

/// Ported from Android `presentation/screen/premium/FeatureItem.kt`.
enum FeatureItem {
    case simple(String)
    case strikethrough(normal: String, strike: String, normalEnd: String)
}
