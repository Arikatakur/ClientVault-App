import Foundation
import CryptoKit

/// KDF parameters stored alongside the vault config so the master key can be
/// re-derived on any device, and cost can be raised over time while staying
/// backward compatible. Defaults follow OWASP guidance for Argon2id.
struct KDFParameters: Codable, Equatable, Sendable {
    enum Algorithm: String, Codable, Sendable {
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
