import Foundation

/// Ciphertext as stored/transmitted. Holds everything needed to decrypt except
/// the key: nonce, ciphertext, auth tag, and a cipher version for forward
/// compatibility. This is what the server sees for vault secrets — never plaintext.
struct EncryptedPayload: Codable, Equatable {
    /// Bump when the cipher/format changes so old items remain decryptable.
    var version: Int
    var nonce: Data
    var ciphertext: Data
    var tag: Data

    static let currentVersion = 1
}
