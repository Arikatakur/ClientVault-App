import Foundation

/// Per-user vault configuration. Stored server-side (it contains no plaintext
/// secret and no key material the server can use): KDF params + salt let the
/// master key be re-derived from the password on any device, and the wrapped DEK
/// is only decryptable with that master key.
struct VaultConfig: Codable, Equatable, Sendable {
    var kdfParameters: KDFParameters
    var salt: Data
    var wrappedDEK: EncryptedPayload
    var cipherVersion: Int
    var createdAt: Date
    var updatedAt: Date
}
