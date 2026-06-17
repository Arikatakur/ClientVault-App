import XCTest
import CryptoKit
@testable import ClientVault

/// End-to-end vault key hierarchy: bootstrap, unlock, item encrypt/decrypt
/// round-trip. Uses reduced KDF cost (8 MiB / 1 iteration) so the test suite
/// runs in reasonable time while still exercising real Argon2id.
final class VaultKeyManagerTests: XCTestCase {
    private let crypto = AESGCMCrypto()
    private var manager: VaultKeyManager!

    private static let fastParams = KDFParameters(
        memoryKiB: 8 * 1024, iterations: 1, parallelism: 1, saltLength: 16, version: 1
    )

    override func setUp() {
        super.setUp()
        manager = VaultKeyManager(crypto: crypto)
    }

    // MARK: - Bootstrap

    func testBootstrapProducesConfig() throws {
        let config = try manager.bootstrap(password: "hunter2", parameters: Self.fastParams)
        XCTAssertEqual(config.kdfParameters.algorithm, .argon2id)
        XCTAssertEqual(config.salt.count, Self.fastParams.saltLength)
        XCTAssertFalse(config.wrappedDEK.ciphertext.isEmpty)
    }

    func testBootstrapProducesUniqueSaltEachCall() throws {
        let c1 = try manager.bootstrap(password: "same", parameters: Self.fastParams)
        let c2 = try manager.bootstrap(password: "same", parameters: Self.fastParams)
        XCTAssertNotEqual(c1.salt, c2.salt, "each vault must have a unique salt")
    }

    // MARK: - Unlock

    func testUnlockWithCorrectPasswordReturnsDEK() throws {
        let password = "correct-horse-battery-staple"
        let config = try manager.bootstrap(password: password, parameters: Self.fastParams)
        let dek = try manager.unlock(password: password, config: config)
        XCTAssertEqual(dek.rawData.count, 32)
    }

    func testUnlockWithWrongPasswordFails() throws {
        let config = try manager.bootstrap(password: "right", parameters: Self.fastParams)
        XCTAssertThrowsError(try manager.unlock(password: "wrong", config: config))
    }

    func testUnlockIsDeterministic() throws {
        let config = try manager.bootstrap(password: "pw", parameters: Self.fastParams)
        let dek1 = try manager.unlock(password: "pw", config: config)
        let dek2 = try manager.unlock(password: "pw", config: config)
        XCTAssertEqual(dek1.rawData, dek2.rawData, "same password+config must always unlock the same DEK")
    }

    // MARK: - Item encrypt / decrypt round-trip

    func testItemEncryptDecryptRoundTrip() throws {
        let config = try manager.bootstrap(password: "vault!", parameters: Self.fastParams)
        let dek = try manager.unlock(password: "vault!", config: config)
        let body = VaultItemBody(secret: "s3cr3t", username: "alice@example.com", url: "https://example.com", notes: nil)
        let bodyData = try JSONEncoder.clientVault.encode(body)
        let sealed = try crypto.seal(bodyData, using: dek)
        let opened = try crypto.open(sealed, using: dek)
        let decoded = try JSONDecoder.clientVault.decode(VaultItemBody.self, from: opened)
        XCTAssertEqual(decoded.secret, body.secret)
        XCTAssertEqual(decoded.username, body.username)
        XCTAssertEqual(decoded.url, body.url)
    }

    func testItemDecryptFailsWithWrongDEK() throws {
        let config = try manager.bootstrap(password: "correct", parameters: Self.fastParams)
        let rightDEK = try manager.unlock(password: "correct", config: config)
        let wrongDEK = crypto.generateDataKey()
        let plaintext = Data("secret".utf8)
        let sealed = try crypto.seal(plaintext, using: rightDEK)
        XCTAssertThrowsError(try crypto.open(sealed, using: wrongDEK))
    }

    // MARK: - Key encryption key

    func testKEKIsDomainSeparatedFromMasterKey() {
        let masterKey = crypto.generateDataKey()
        let kek = manager.keyEncryptionKey(from: masterKey)
        XCTAssertNotEqual(masterKey.rawData, kek.rawData, "KEK must differ from MK")
        XCTAssertEqual(kek.rawData.count, 32)
    }
}

private extension SymmetricKey {
    var rawData: Data { withUnsafeBytes { Data($0) } }
}
