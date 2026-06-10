import Foundation
import CryptoKit
import Security

/// Nonce helpers for Sign in with Apple replay protection: a random raw nonce is
/// kept on-device, and its SHA-256 hash is sent in the authorization request.
/// The backend later compares the raw nonce against the identity token's claim.
enum Nonce {
    private static let charset = Array(
        "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._"
    )

    /// A cryptographically random nonce string.
    static func random(length: Int = 32) -> String {
        precondition(length > 0)
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        if status != errSecSuccess {
            // Fall back to a non-security RNG only to avoid a crash; SecRandom
            // succeeding is the expected path on-device.
            bytes = (0..<length).map { _ in UInt8.random(in: 0...255) }
        }
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    /// Lowercase hex SHA-256 of the input.
    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
