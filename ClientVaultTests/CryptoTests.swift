import XCTest
import CryptoKit
@testable import ClientVault

/// Crypto is security-critical, so the primitives carry the most tests:
/// authenticated encryption round-trips, tamper/wrong-key rejection, key
/// wrapping, nonce uniqueness, and the honest "Argon2id not yet wired" guard.
final class CryptoTests: XCTestCase {
    private let crypto = AESGCMCrypto()

    func testSealOpenRoundTrip() throws {
        let key = crypto.generateDataKey()
        let plaintext = Data("super secret token".utf8)

        let payload = try crypto.seal(plaintext, using: key)
        XCTAssertNotEqual(payload.ciphertext, plaintext, "ciphertext must not equal plaintext")

        let opened = try crypto.open(payload, using: key)
        XCTAssertEqual(opened, plaintext)
    }

    func testOpenWithWrongKeyFails() throws {
        let key = crypto.generateDataKey()
        let wrongKey = crypto.generateDataKey()
        let payload = try crypto.seal(Data("x".utf8), using: key)

        XCTAssertThrowsError(try crypto.open(payload, using: wrongKey)) { error in
            XCTAssertEqual(error as? CryptoError, .openFailed)
        }
    }

    func testTamperedCiphertextFailsAuthentication() throws {
        let key = crypto.generateDataKey()
        var payload = try crypto.seal(Data("hello world".utf8), using: key)

        var bytes = [UInt8](payload.ciphertext)
        if bytes.isEmpty { bytes = [0] }
        bytes[0] ^= 0xFF                    // flip a byte
        payload.ciphertext = Data(bytes)

        XCTAssertThrowsError(try crypto.open(payload, using: key))
    }

    func testNonceIsUniquePerSeal() throws {
        let key = crypto.generateDataKey()
        let a = try crypto.seal(Data("same".utf8), using: key)
        let b = try crypto.seal(Data("same".utf8), using: key)

        XCTAssertNotEqual(a.nonce, b.nonce, "GCM nonces must never repeat for a key")
        XCTAssertNotEqual(a.ciphertext, b.ciphertext)
    }

    func testUnsupportedVersionThrows() throws {
        let key = crypto.generateDataKey()
        var payload = try crypto.seal(Data("v".utf8), using: key)
        payload.version = 999

        XCTAssertThrowsError(try crypto.open(payload, using: key)) { error in
            XCTAssertEqual(error as? CryptoError, .unsupportedVersion(999))
        }
    }

    func testKeyWrapUnwrapRoundTrip() throws {
        let kek = crypto.generateDataKey()
        let dek = crypto.generateDataKey()

        let wrapped = try crypto.wrapKey(dek, using: kek)
        let unwrapped = try crypto.unwrapKey(wrapped, using: kek)

        XCTAssertEqual(unwrapped.rawData, dek.rawData)
    }

    func testEncryptedPayloadJSONRoundTrip() throws {
        let key = crypto.generateDataKey()
        let payload = try crypto.seal(Data("persist me".utf8), using: key)

        let data = try JSONEncoder.clientVault.encode(payload)
        let decoded = try JSONDecoder.clientVault.decode(EncryptedPayload.self, from: data)

        XCTAssertEqual(decoded, payload)
        XCTAssertEqual(try crypto.open(decoded, using: key), Data("persist me".utf8))
    }

    func testArgon2idDerivesDeterministically() throws {
        let kdf = Argon2idKeyDerivation()
        // Salt must be exactly 16 bytes (crypto_pwhash_SALTBYTES).
        let salt = Data(repeating: 0xAB, count: 16)
        let params = KDFParameters(memoryKiB: 8 * 1024, iterations: 1, parallelism: 1,
                                   saltLength: 16, version: 1)
        // Same inputs must produce identical output across calls.
        let key1 = try kdf.deriveKey(password: "test-password", salt: salt, parameters: params)
        let key2 = try kdf.deriveKey(password: "test-password", salt: salt, parameters: params)
        XCTAssertEqual(key1.rawData, key2.rawData, "KDF must be deterministic")
        XCTAssertEqual(key1.rawData.count, 32, "output must be 256-bit")
    }

    func testArgon2idDifferentPasswordProducesDifferentKey() throws {
        let kdf = Argon2idKeyDerivation()
        let salt = Data(repeating: 0xCD, count: 16)
        let params = KDFParameters(memoryKiB: 8 * 1024, iterations: 1, parallelism: 1,
                                   saltLength: 16, version: 1)
        let key1 = try kdf.deriveKey(password: "correct-horse", salt: salt, parameters: params)
        let key2 = try kdf.deriveKey(password: "battery-staple", salt: salt, parameters: params)
        XCTAssertNotEqual(key1.rawData, key2.rawData, "different passwords must produce different keys")
    }

    func testArgon2idWrongSaltLengthThrows() {
        let kdf = Argon2idKeyDerivation()
        XCTAssertThrowsError(
            try kdf.deriveKey(password: "pw", salt: Data([0, 1, 2, 3]), parameters: .default)
        ) { error in
            XCTAssertEqual(error as? CryptoError, .invalidKey)
        }
    }

    func testKeyEncryptionKeyIsDeterministic() {
        let manager = VaultKeyManager(crypto: crypto)
        let masterKey = crypto.generateDataKey()

        let kek1 = manager.keyEncryptionKey(from: masterKey)
        let kek2 = manager.keyEncryptionKey(from: masterKey)

        XCTAssertEqual(kek1.rawData, kek2.rawData, "same MK must derive the same KEK")
    }
}

private extension SymmetricKey {
    var rawData: Data { withUnsafeBytes { Data($0) } }
}
