import Foundation
import CryptoKit

/// AES-256-GCM implementation of `CryptoService` using CryptoKit. A fresh random
/// nonce is generated per seal (CryptoKit default), which is critical for GCM
/// security — never reuse a nonce with the same key.
struct AESGCMCrypto: CryptoService {
    func seal(_ plaintext: Data, using key: SymmetricKey) throws -> EncryptedPayload {
        do {
            let box = try AES.GCM.seal(plaintext, using: key)
            return EncryptedPayload(
                version: EncryptedPayload.currentVersion,
                nonce: Data(box.nonce),
                ciphertext: box.ciphertext,
                tag: box.tag
            )
        } catch {
            throw CryptoError.sealFailed
        }
    }

    func open(_ payload: EncryptedPayload, using key: SymmetricKey) throws -> Data {
        guard payload.version == EncryptedPayload.currentVersion else {
            throw CryptoError.unsupportedVersion(payload.version)
        }
        do {
            let box = try AES.GCM.SealedBox(
                nonce: AES.GCM.Nonce(data: payload.nonce),
                ciphertext: payload.ciphertext,
                tag: payload.tag
            )
            return try AES.GCM.open(box, using: key)
        } catch {
            // Wrong key, tampered ciphertext, or bad nonce all surface here.
            throw CryptoError.openFailed
        }
    }

    func generateDataKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }

    func wrapKey(_ key: SymmetricKey, using kek: SymmetricKey) throws -> EncryptedPayload {
        let raw = key.withUnsafeBytes { Data($0) }
        return try seal(raw, using: kek)
    }

    func unwrapKey(_ payload: EncryptedPayload, using kek: SymmetricKey) throws -> SymmetricKey {
        let raw = try open(payload, using: kek)
        guard raw.count == 32 else { throw CryptoError.invalidKey }
        return SymmetricKey(data: raw)
    }
}
