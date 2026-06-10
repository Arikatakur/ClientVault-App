import Foundation
import CryptoKit

enum CryptoError: Error, Equatable {
    case sealFailed
    case openFailed
    case invalidKey
    case unsupportedVersion(Int)
    /// A code path that depends on a component not yet integrated (e.g. Argon2id).
    case notImplemented(String)
}

/// Authenticated symmetric encryption + key wrapping. The only crypto used is
/// AES-256-GCM from Apple's CryptoKit — no custom cryptography.
protocol CryptoService: Sendable {
    /// Encrypts plaintext under `key`, generating a fresh random nonce.
    func seal(_ plaintext: Data, using key: SymmetricKey) throws -> EncryptedPayload
    /// Decrypts and verifies a payload. Throws `openFailed` if authentication fails.
    func open(_ payload: EncryptedPayload, using key: SymmetricKey) throws -> Data

    /// Generates a random 256-bit data-encryption key (DEK).
    func generateDataKey() -> SymmetricKey

    /// Wraps (encrypts) a key under a key-encryption-key (KEK).
    func wrapKey(_ key: SymmetricKey, using kek: SymmetricKey) throws -> EncryptedPayload
    /// Unwraps a previously wrapped key.
    func unwrapKey(_ payload: EncryptedPayload, using kek: SymmetricKey) throws -> SymmetricKey
}
