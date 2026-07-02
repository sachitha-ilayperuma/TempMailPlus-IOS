import Foundation

/// Ported 1:1 from Android `data/security/SecretConstants.kt`.
/// Same AES-CBC-encrypted base64 blobs, key, and IV — decrypted at runtime by `Decryptor`
/// to the same base URL / WebSocket URL the Android app uses.
enum SecretConstants {
    // Encrypted Base URL (split into 2 parts)
    private static let bx1 = "5xq2XmtuvgFIi7Jrxe5vxZs+PpLtzP8klTV4GStGwRza"
    private static let bx2 = "3leVr/TxezjoN3Ke4Ctw2fpljGxVAW5psntSnCJfTQ=="
    static let BURL = bx1 + bx2

    private static let wx1 = "1tarTbxvJoUFAcatPMm95a6bvy+sTUMq2YLEHC+Zq6bq8"
    private static let wx2 = "9So5vQn+CEjc5aRjnsS95Ey1Tsw1ANeOw7etoDATg=="
    static let WURL = wx1 + wx2

    private static let kx1 = "STKUKjjMdAC/77n5J5kvm0X"
    private static let kx2 = "bApWIN3ouef/cQ1egYlU="
    static let BKEY = kx1 + kx2

    private static let ivx1 = "OY12pTwY5jdX"
    private static let ivx2 = "oB/i+v35Cw=="
    static let BIV = ivx1 + ivx2
}
