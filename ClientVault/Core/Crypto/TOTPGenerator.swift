import Foundation
import CryptoKit

/// RFC 6238 TOTP generator. Seed is stored AES-GCM-encrypted in the vault;
/// codes are generated locally and never transmitted.
enum TOTPGenerator {

    static let period: TimeInterval = 30

    /// Returns the current 6-digit TOTP code for the given base32 seed.
    static func currentCode(seed: String) throws -> String {
        let keyBytes = try base32Decode(seed)
        let counter = UInt64(Date().timeIntervalSince1970 / period)
        return hotp(key: keyBytes, counter: counter)
    }

    /// Seconds remaining in the current 30-second window.
    static var secondsRemaining: Int {
        let elapsed = Int(Date().timeIntervalSince1970) % Int(period)
        return Int(period) - elapsed
    }

    // MARK: - HOTP (RFC 4226)

    private static func hotp(key: [UInt8], counter: UInt64) -> String {
        var c = counter.bigEndian
        let counterData = Data(bytes: &c, count: MemoryLayout<UInt64>.size)
        let symmetricKey = SymmetricKey(data: Data(key))
        let mac = HMAC<Insecure.SHA1>.authenticationCode(for: counterData, using: symmetricKey)
        let hmacBytes = Array(mac)

        let offset = Int(hmacBytes[hmacBytes.count - 1] & 0x0F)
        let truncated: UInt32 =
            (UInt32(hmacBytes[offset])     & 0x7F) << 24 |
            (UInt32(hmacBytes[offset + 1]) & 0xFF) << 16 |
            (UInt32(hmacBytes[offset + 2]) & 0xFF) <<  8 |
            (UInt32(hmacBytes[offset + 3]) & 0xFF)

        let code = Int(truncated) % 1_000_000
        return String(format: "%06d", code)
    }

    // MARK: - Base32 decoder (RFC 4648)

    private static let base32Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

    static func base32Decode(_ input: String) throws -> [UInt8] {
        let cleaned = input
            .uppercased()
            .filter { base32Alphabet.contains($0) }

        var bits = 0
        var bitsCount = 0
        var result: [UInt8] = []

        for char in cleaned {
            guard let value = base32Alphabet.firstIndex(of: char) else { continue }
            let index = base32Alphabet.distance(from: base32Alphabet.startIndex, to: value)
            bits = (bits << 5) | index
            bitsCount += 5
            if bitsCount >= 8 {
                bitsCount -= 8
                result.append(UInt8((bits >> bitsCount) & 0xFF))
            }
        }

        return result
    }

    /// Parses an `otpauth://totp/...` URL and extracts seed, issuer, and account.
    static func parseOTPAuthURL(_ urlString: String) -> (seed: String, issuer: String?, account: String?)? {
        guard let url = URL(string: urlString),
              url.scheme == "otpauth",
              url.host == "totp" else { return nil }

        let label = url.path.hasPrefix("/") ? String(url.path.dropFirst()) : url.path
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let params = Dictionary(
            uniqueKeysWithValues: (components?.queryItems ?? []).compactMap { item -> (String, String)? in
                guard let value = item.value else { return nil }
                return (item.name, value)
            }
        )

        guard let secret = params["secret"], !secret.isEmpty else { return nil }

        let issuer = params["issuer"]
        let account: String?
        if label.contains(":") {
            account = String(label.split(separator: ":", maxSplits: 1).last ?? "")
        } else {
            account = label.isEmpty ? nil : label
        }

        return (secret, issuer, account)
    }
}
