import Foundation
import CryptoKit
import Sodium

/// Argon2id KDF backed by libsodium's `crypto_pwhash` (Argon2id13).
///
/// Sodium.PWHash.SaltBytes == 16 (crypto_pwhash_SALTBYTES). KDFParameters
/// defaults to 16-byte salts so new vaults always produce a valid salt length.
/// If a stored config has a different length, `deriveKey` throws `.invalidKey`.
struct Argon2idKeyDerivation: KeyDerivation, Sendable {
    func deriveKey(password: String, salt: Data, parameters: KDFParameters) throws -> SymmetricKey {
        guard parameters.algorithm == .argon2id else {
            throw CryptoError.notImplemented("Unsupported KDF algorithm: \(parameters.algorithm.rawValue)")
        }
        let pwHash = Sodium().pwHash
        guard salt.count == pwHash.SaltBytes else {
            throw CryptoError.invalidKey
        }
        guard let derived = pwHash.hash(
            outputLength: 32,
            passwd: Array(password.utf8),
            salt: Array(salt),
            opsLimit: parameters.iterations,
            memLimit: parameters.memoryKiB * 1024,
            alg: .Argon2ID13
        ) else {
            throw CryptoError.sealFailed
        }
        return SymmetricKey(data: Data(derived))
    }
}
