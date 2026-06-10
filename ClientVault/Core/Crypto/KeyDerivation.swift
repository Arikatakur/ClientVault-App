import Foundation
import CryptoKit

/// KDF parameters stored alongside the vault config so the master key can be
/// re-derived on any device, and cost can be raised over time while staying
/// backward compatible. Defaults follow OWASP guidance for Argon2id.
struct KDFParameters: Codable, Equatable {
    enum Algorithm: String, Codable {
        case argon2id
    }

    var algorithm: Algorithm = .argon2id
    var memoryKiB: Int = 64 * 1024     // 64 MiB
    var iterations: Int = 3
    var parallelism: Int = 1
    var saltLength: Int = 16
    var version: Int = 1

    static let `default` = KDFParameters()
}

/// Derives a symmetric key from a password + salt. The vault's master key (MK)
/// comes from here.
protocol KeyDerivation: Sendable {
    func deriveKey(password: String, salt: Data, parameters: KDFParameters) throws -> SymmetricKey
}

/// Argon2id KDF.
///
/// Argon2 is **not** part of CryptoKit. A vetted implementation (e.g. swift-sodium
/// / libsodium) is integrated in the Vault phase — see docs/security-model.md.
/// Until then this throws rather than silently substituting a weaker KDF, so no
/// code can accidentally ship password hashing that isn't Argon2id.
struct Argon2idKeyDerivation: KeyDerivation {
    func deriveKey(password: String, salt: Data, parameters: KDFParameters) throws -> SymmetricKey {
        throw CryptoError.notImplemented(
            "Argon2id KDF pending a vetted dependency (swift-sodium). See docs/security-model.md."
        )
    }
}
