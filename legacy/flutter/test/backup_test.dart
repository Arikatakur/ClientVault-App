import 'dart:convert';
import 'dart:typed_data';

import 'package:clientvault/core/crypto/crypto_service.dart';
import 'package:clientvault/data/local/app_database.dart';
import 'package:clientvault/features/backup/backup_codec.dart';
import 'package:clientvault/features/backup/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Cheap Argon2id so the suite stays fast; real backups use KdfParams.defaults.
const _testKdf = KdfParams(memory: 64, iterations: 1, parallelism: 1);

void main() {
  final codec = BackupCodec(CryptoService());

  group('BackupCodec', () {
    final payload = <String, Object?>{
      'clients': [
        {'id': 'c1', 'name': 'ACME'},
      ],
      'note': 'round trip',
    };

    test('seals and opens with the right passphrase', () async {
      final bytes = await codec.seal(
        payload: payload,
        passphrase: 'open sesame',
        params: _testKdf,
      );
      final reopened = await codec.open(bytes, 'open sesame');
      expect(reopened, payload);
    });

    test('rejects a wrong passphrase', () async {
      final bytes = await codec.seal(
        payload: payload,
        passphrase: 'open sesame',
        params: _testKdf,
      );
      expect(
        () => codec.open(bytes, 'open sesamE'),
        throwsA(
          isA<BackupException>().having(
            (e) => e.message,
            'message',
            contains('passphrase'),
          ),
        ),
      );
    });

    test('rejects files that are not backups', () {
      expect(
        () => codec.open(utf8.encode('hello world'), 'x'),
        throwsA(isA<BackupException>()),
      );
      expect(
        () => codec.open(utf8.encode('{"format":"other"}'), 'x'),
        throwsA(isA<BackupException>()),
      );
    });

    test('rejects backups from a newer format version', () async {
      final bytes = await codec.seal(
        payload: payload,
        passphrase: 'x',
        params: _testKdf,
      );
      final envelope = (jsonDecode(utf8.decode(bytes)) as Map)
          .cast<String, Object?>();
      envelope['version'] = BackupCodec.version + 1;
      expect(
        () => codec.open(utf8.encode(jsonEncode(envelope)), 'x'),
        throwsA(
          isA<BackupException>().having(
            (e) => e.message,
            'message',
            contains('newer'),
          ),
        ),
      );
    });
  });

  group('BackupService row mapping', () {
    final now = DateTime.fromMillisecondsSinceEpoch(1760000000000);
    final rows = BackupRows(
      clients: [
        Client(
          id: 'c1',
          name: 'ACME',
          company: 'ACME GmbH',
          email: null,
          phone: null,
          notes: null,
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      projects: [
        Project(
          id: 'p1',
          clientId: 'c1',
          name: 'Website',
          description: null,
          status: 'active',
          budget: 4000,
          currency: 'ILS',
          startDate: null,
          dueDate: now,
          repoId: null,
          repoFullName: 'acme/site',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      payments: [
        Payment(
          id: 'pay1',
          projectId: 'p1',
          amount: 4000,
          paidAmount: 1000,
          currency: 'ILS',
          status: 'sent',
          issuedDate: now,
          dueDate: now,
          paidDate: null,
          notes: null,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      vaultItems: [
        VaultItem(
          id: 'v1',
          type: 'password',
          title: 'Server root',
          clientId: 'c1',
          projectId: null,
          ciphertext: Uint8List.fromList([1, 2, 3]),
          nonce: Uint8List.fromList([4, 5, 6]),
          mac: Uint8List.fromList([7, 8, 9]),
          createdAt: now,
          updatedAt: now,
        ),
      ],
      vaultConfig: VaultConfig(
        id: 'singleton',
        kdfSalt: Uint8List.fromList([1, 1, 1]),
        kdfMemory: 19456,
        kdfIterations: 2,
        kdfParallelism: 1,
        wrappedDek: Uint8List.fromList([2, 2, 2]),
        wrappedDekNonce: Uint8List.fromList([3, 3, 3]),
        wrappedDekMac: Uint8List.fromList([4, 4, 4]),
        createdAt: now,
        updatedAt: now,
      ),
    );

    test('rows survive a full JSON round trip', () {
      // Through real JSON so types degrade exactly like they do on disk.
      final json =
          (jsonDecode(jsonEncode(BackupService.payloadFromRows(rows))) as Map)
              .cast<String, Object?>();
      final restored = BackupService.rowsFromPayload(json);

      expect(restored.clients.single, rows.clients.single);
      expect(restored.projects.single, rows.projects.single);
      expect(restored.payments.single, rows.payments.single);
      expect(restored.vaultItems.single, rows.vaultItems.single);
      expect(restored.vaultConfig, rows.vaultConfig);
    });

    test('a backup without a vault restores without one', () {
      final payload = BackupService.payloadFromRows(
        const BackupRows(
          clients: [],
          projects: [],
          payments: [],
          vaultItems: [],
        ),
      );
      final restored = BackupService.rowsFromPayload(payload);
      expect(restored.vaultConfig, isNull);
      expect(restored.clients, isEmpty);
    });
  });
}
