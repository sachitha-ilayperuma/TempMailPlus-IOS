import Foundation
import CommonCrypto

/// Ported from Android `data/security/Decryptor.kt`.
/// AES/CBC/PKCS7 decryption of base64 inputs. Android's `AES/CBC/PKCS7Padding` maps to
/// CommonCrypto's `kCCAlgorithmAES` + `kCCOptionPKCS7Padding` in CBC mode (the default
/// when an IV is supplied and ECB is not requested).
enum Decryptor {
    enum DecryptError: Error { case badBase64, cryptFailed(Int32) }

    static func decryptBase64(encryptedBase64: String, keyBase64: String, ivBase64: String) throws -> String {
        guard
            let key = Data(base64Encoded: keyBase64),
            let iv = Data(base64Encoded: ivBase64),
            let cipherText = Data(base64Encoded: encryptedBase64)
        else { throw DecryptError.badBase64 }

        var outLength = 0
        // Output buffer: ciphertext length + one block for padding headroom.
        var outBytes = [UInt8](repeating: 0, count: cipherText.count + kCCBlockSizeAES128)

        let status: CCCryptorStatus = key.withUnsafeBytes { keyPtr in
            iv.withUnsafeBytes { ivPtr in
                cipherText.withUnsafeBytes { dataPtr in
                    CCCrypt(
                        CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyPtr.baseAddress, key.count,
                        ivPtr.baseAddress,
                        dataPtr.baseAddress, cipherText.count,
                        &outBytes, outBytes.count,
                        &outLength
                    )
                }
            }
        }

        guard status == kCCSuccess else { throw DecryptError.cryptFailed(status) }
        return String(decoding: outBytes.prefix(outLength), as: UTF8.self)
    }
}
