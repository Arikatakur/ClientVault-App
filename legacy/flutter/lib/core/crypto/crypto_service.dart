import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// A sealed AES-256-GCM payload: the ciphertext, the unique nonce it was sealed
/// with, and the GCM authentication tag.
class SealedBytes {
  const SealedBytes({
    required this.cipherText,
    required this.nonce,
    required this.mac,
  });

  final List<int> cipherText;
  final List<int> nonce;
  final List<int> mac;
}

/// Argon2id parameters, persisted next to the salt so the KEK can always be
/// re-derived even if the defaults change in a future version.
class KdfParams {
  const KdfParams({
    required this.memory,
    required this.iterations,
    required this.parallelism,
  });

  /// Memory cost in kibibytes.
  final int memory;
  final int iterations;
  final int parallelism;

  /// OWASP-style baseline for Argon2id (19 MiB, t=2, p=1).
  static const KdfParams defaults = KdfParams(
    memory: 19456,
    iterations: 2,
    parallelism: 1,
  );
}

/// Owns the vault's cryptographic primitives and nothing else — it never holds
/// or persists key material. Callers keep the in-memory data key (DEK) and pass
/// it in. Envelope encryption: a random DEK seals each item, and the DEK itself
/// is sealed by a key-encryption key (KEK) derived from the master password.
class CryptoService {
  CryptoService();

  static const int keyLength = 32; // 256-bit
  static const int saltLength = 16;

  final AesGcm _aes = AesGcm.with256bits();
  final Random _random = Random.secure();

  /// A cryptographically-random 256-bit data key (the DEK).
  SecretKey newDataKey() => SecretKeyData.random(length: keyLength);

  /// A fresh random KDF salt.
  Uint8List newSalt() => randomBytes(saltLength);

  /// Derives the 256-bit key-encryption key (KEK) from the master [password].
  Future<SecretKey> deriveKek(
    String password,
    List<int> salt,
    KdfParams params,
  ) {
    final argon2 = Argon2id(
      parallelism: params.parallelism,
      memory: params.memory,
      iterations: params.iterations,
      hashLength: keyLength,
    );
    return argon2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  /// Seals [plaintext] with AES-256-GCM under [key] using a fresh random nonce.
  Future<SealedBytes> seal(List<int> plaintext, SecretKey key) async {
    final box = await _aes.encrypt(plaintext, secretKey: key);
    return SealedBytes(
      cipherText: box.cipherText,
      nonce: box.nonce,
      mac: box.mac.bytes,
    );
  }

  /// Opens a [sealed] payload. Throws [SecretBoxAuthenticationError] if [key]
  /// is wrong or the ciphertext was tampered with — that is how a wrong master
  /// password is detected.
  Future<List<int>> open(SealedBytes sealed, SecretKey key) {
    final box = SecretBox(
      sealed.cipherText,
      nonce: sealed.nonce,
      mac: Mac(sealed.mac),
    );
    return _aes.decrypt(box, secretKey: key);
  }

  /// `length` cryptographically-secure random bytes.
  Uint8List randomBytes(int length) {
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }
}
