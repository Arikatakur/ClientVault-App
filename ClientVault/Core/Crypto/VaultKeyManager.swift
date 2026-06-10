import Foundation
import CryptoKit
import Security

/// Orchestrates the vault key hierarchy described in the blueprint:
///
///   password ──Argon2id──▶ Master Key (MK)
///   MK ──HKDF──▶ Key-Encryption-Key (KEK)
///   DEK (random 256-bit) ──wrap under KEK──▶ stored wrapped DEK
///   vault item secret ──AES-GCM under DEK──▶ ciphertext (uploaded)
///
/// The server only ever stores the wrapped DEK + KDF params + ciphertext, never
/// the MK or plaintext. Methods that need the password KDF throw
/// `CryptoError.notImplemented` until Argon2id is integrated — the structure is
/// here so the Vault phase is wiring, not redesign.
struct VaultKeyManager {
    let crypto: CryptoService
    let kdf: KeyDerivation

    init(crypto: CryptoService, kdf: KeyDerivation = Argon2idKeyDerivation()) {
        self.crypto = crypto
        self.kdf = kdf
    }

    /// Domain-separated KEK derived from the MK, so the raw MK is never used
    /// directly as an encryption key.
    func keyEncryptionKey(from masterKey: SymmetricKey) -> SymmetricKey {
        HKDF<SHA256>.deriveKey(
            inputKeyMaterial: masterKey,
            info: Data("clientvault.kek.v1".utf8),
            outputByteCount: 32
        )
    }

    /// Creates a brand-new vault: derive MK from password, generate a DEK, and
    /// return the wrapped DEK plus the config to persist server-side.
    func bootstrap(password: String, parameters: KDFParameters = .default) throws -> VaultConfig {
        let salt = Self.randomSalt(length: parameters.saltLength)
        let masterKey = try kdf.deriveKey(password: password, salt: salt, parameters: parameters)
        let kek = keyEncryptionKey(from: masterKey)
        let dek = crypto.generateDataKey()
        let wrappedDEK = try crypto.wrapKey(dek, using: kek)
        return VaultConfig(
            kdfParameters: parameters,
            salt: salt,
            wrappedDEK: wrappedDEK,
            cipherVersion: EncryptedPayload.currentVersion,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    /// Unlocks a vault: re-derive MK from password + stored salt, then unwrap the DEK.
    func unlock(password: String, config: VaultConfig) throws -> SymmetricKey {
        let masterKey = try kdf.deriveKey(
            password: password,
            salt: config.salt,
            parameters: config.kdfParameters
        )
        let kek = keyEncryptionKey(from: masterKey)
        return try crypto.unwrapKey(config.wrappedDEK, using: kek)
    }

    static func randomSalt(length: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return Data(bytes)
    }
}
