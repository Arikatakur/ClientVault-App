// Validates the vault's envelope encryption end to end on the Dart VM.

import 'dart:convert';

import 'package:clientvault/core/crypto/crypto_service.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = CryptoService();
  // Light KDF params keep the test fast; production uses KdfParams.defaults.
  const params = KdfParams(memory: 256, iterations: 1, parallelism: 1);

  group('CryptoService envelope encryption', () {
    test('wraps and unwraps the DEK with the correct password', () async {
      final salt = service.newSalt();
      final dekBytes = await service.newDataKey().extractBytes();

      final kek = await service.deriveKek('correct horse', salt, params);
      final wrapped = await service.seal(dekBytes, kek);

      final kekAgain = await service.deriveKek('correct horse', salt, params);
      final unwrapped = await service.open(wrapped, kekAgain);

      expect(unwrapped, equals(dekBytes));
    });

    test('rejects a wrong master password', () async {
      final salt = service.newSalt();
      final dekBytes = await service.newDataKey().extractBytes();

      final kek = await service.deriveKek('right', salt, params);
      final wrapped = await service.seal(dekBytes, kek);

      final wrongKek = await service.deriveKek('wrong', salt, params);
      await expectLater(
        service.open(wrapped, wrongKek),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('seals and opens an item payload under the DEK', () async {
      final dek = service.newDataKey();
      const json = '{"username":"a","secret":"s3cr3t"}';

      final sealed = await service.seal(utf8.encode(json), dek);
      final opened = await service.open(sealed, dek);

      expect(utf8.decode(opened), json);
    });

    test('uses a unique nonce per seal', () async {
      final dek = service.newDataKey();
      final payload = utf8.encode('same');

      final a = await service.seal(payload, dek);
      final b = await service.seal(payload, dek);

      expect(a.nonce, isNot(equals(b.nonce)));
      expect(a.cipherText, isNot(equals(b.cipherText)));
    });

    test('re-wrapping the DEK opens under the new key only', () async {
      final dekBytes = await service.newDataKey().extractBytes();
      final kek1 = await service.deriveKek(
        'old-pass',
        service.newSalt(),
        params,
      );
      final wrapped1 = await service.seal(dekBytes, kek1);

      // Change password: unwrap with the old key, re-wrap with a new salt+key.
      final unwrapped = await service.open(wrapped1, kek1);
      final kek2 = await service.deriveKek(
        'new-pass',
        service.newSalt(),
        params,
      );
      final wrapped2 = await service.seal(unwrapped, kek2);

      expect(await service.open(wrapped2, kek2), equals(dekBytes));
      await expectLater(
        service.open(wrapped2, kek1),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });
  });
}
