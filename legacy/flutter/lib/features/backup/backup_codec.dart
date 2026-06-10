import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart'
    show SecretBoxAuthenticationError;

import '../../core/crypto/crypto_service.dart';

/// A user-facing backup failure ([message] is shown verbatim).
class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Seals and opens the on-disk backup envelope: a small JSON wrapper carrying
/// the KDF parameters and an AES-256-GCM payload encrypted under a key derived
/// from the user's backup passphrase with Argon2id. The KDF parameters travel
/// inside the file, so future cost increases never break old backups.
class BackupCodec {
  BackupCodec(this._crypto);

  final CryptoService _crypto;

  static const String format = 'clientvault-backup';
  static const int version = 1;

  Future<Uint8List> seal({
    required Map<String, Object?> payload,
    required String passphrase,
    KdfParams params = KdfParams.defaults,
  }) async {
    final salt = _crypto.newSalt();
    final key = await _crypto.deriveKek(passphrase, salt, params);
    final sealed = await _crypto.seal(utf8.encode(jsonEncode(payload)), key);
    final envelope = <String, Object?>{
      'format': format,
      'version': version,
      'createdAt': DateTime.now().toIso8601String(),
      'kdf': {
        'salt': base64Encode(salt),
        'memory': params.memory,
        'iterations': params.iterations,
        'parallelism': params.parallelism,
      },
      'nonce': base64Encode(sealed.nonce),
      'mac': base64Encode(sealed.mac),
      'data': base64Encode(sealed.cipherText),
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  Future<Map<String, Object?>> open(List<int> bytes, String passphrase) async {
    final Map<String, Object?> envelope;
    try {
      envelope = (jsonDecode(utf8.decode(bytes)) as Map)
          .cast<String, Object?>();
    } on Exception {
      throw const BackupException('This is not a ClientVault backup file.');
    }
    if (envelope['format'] != format) {
      throw const BackupException('This is not a ClientVault backup file.');
    }
    if ((envelope['version'] as int? ?? 0) > version) {
      throw const BackupException(
        'This backup comes from a newer version of ClientVault — update the '
        'app, then import again.',
      );
    }

    final kdf = (envelope['kdf'] as Map).cast<String, Object?>();
    final key = await _crypto.deriveKek(
      passphrase,
      base64Decode(kdf['salt'] as String),
      KdfParams(
        memory: kdf['memory'] as int,
        iterations: kdf['iterations'] as int,
        parallelism: kdf['parallelism'] as int,
      ),
    );
    try {
      final plain = await _crypto.open(
        SealedBytes(
          cipherText: base64Decode(envelope['data'] as String),
          nonce: base64Decode(envelope['nonce'] as String),
          mac: base64Decode(envelope['mac'] as String),
        ),
        key,
      );
      return (jsonDecode(utf8.decode(plain)) as Map).cast<String, Object?>();
    } on SecretBoxAuthenticationError {
      throw const BackupException('Wrong passphrase for this backup.');
    }
  }
}
