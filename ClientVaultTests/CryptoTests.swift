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

    func testArgon2idNotYetImplemented() {
        // Until a vetted Argon2 dependency lands, the KDF must throw rather than
        // silently fall back to a weaker derivation.
        let kdf = Argon2idKeyDerivation()
        XCTAssertThrowsError(
            try kdf.deriveKey(password: "pw", salt: Data([0, 1, 2, 3]), parameters: .default)
        )
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
