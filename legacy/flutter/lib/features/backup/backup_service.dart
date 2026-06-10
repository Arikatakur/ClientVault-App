import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/storage/secure_store_provider.dart';
import '../../data/local/app_database.dart';
import '../../data/providers/database_provider.dart';
import '../vault/vault_controller.dart' show cryptoServiceProvider;
import 'backup_codec.dart';

/// What a restore brought back, for the confirmation message.
class BackupSummary {
  const BackupSummary({
    required this.clients,
    required this.projects,
    required this.payments,
    required this.vaultItems,
    required this.hasVault,
  });

  final int clients;
  final int projects;
  final int payments;
  final int vaultItems;
  final bool hasVault;
}

/// Creates and restores passphrase-encrypted backups of everything in the
/// database. Vault items stay sealed under their original DEK inside the
/// backup (and the whole file is encrypted again under the passphrase), so a
/// restored vault opens with the master password it had when exported.
class BackupService {
  BackupService(this._db, this._codec, {this.onAfterRestore});

  final AppDatabase _db;
  final BackupCodec _codec;

  /// Post-restore cleanup supplied by the app (drop the biometric DEK stash,
  /// wipe orphaned attachment files). Injectable so tests can omit it.
  final Future<void> Function()? onAfterRestore;

  Future<Uint8List> createBackup(String passphrase) async {
    final rows = await _db.exportAllRows();
    return _codec.seal(payload: payloadFromRows(rows), passphrase: passphrase);
  }

  Future<BackupSummary> restoreBackup(
    List<int> bytes,
    String passphrase,
  ) async {
    final payload = await _codec.open(bytes, passphrase);
    final BackupRows rows;
    try {
      rows = rowsFromPayload(payload);
    } on Exception {
      throw const BackupException('This backup file is damaged.');
    }
    await _db.replaceAllRows(rows);
    await onAfterRestore?.call();
    return BackupSummary(
      clients: rows.clients.length,
      projects: rows.projects.length,
      payments: rows.payments.length,
      vaultItems: rows.vaultItems.length,
      hasVault: rows.vaultConfig != null,
    );
  }

  /// Pure mapping between Drift rows and the JSON payload — kept static so the
  /// round-trip is unit-testable without a database.
  static Map<String, Object?> payloadFromRows(BackupRows rows) => {
    'clients': [for (final r in rows.clients) r.toJson()],
    'projects': [for (final r in rows.projects) r.toJson()],
    'payments': [for (final r in rows.payments) r.toJson()],
    'vaultItems': [for (final r in rows.vaultItems) r.toJson()],
    'vaultConfig': rows.vaultConfig?.toJson(),
  };

  static BackupRows rowsFromPayload(Map<String, Object?> payload) {
    List<T> rowsOf<T>(String key, T Function(Map<String, dynamic>) fromJson) =>
        [
          for (final entry in (payload[key] as List? ?? const []))
            fromJson((entry as Map).cast<String, dynamic>()),
        ];

    final vaultConfig = payload['vaultConfig'];
    return BackupRows(
      clients: rowsOf('clients', Client.fromJson),
      projects: rowsOf('projects', Project.fromJson),
      payments: rowsOf('payments', Payment.fromJson),
      vaultItems: rowsOf('vaultItems', VaultItem.fromJson),
      vaultConfig: vaultConfig == null
          ? null
          : VaultConfig.fromJson((vaultConfig as Map).cast<String, dynamic>()),
    );
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    ref.watch(databaseProvider),
    BackupCodec(ref.watch(cryptoServiceProvider)),
    onAfterRestore: () async {
      // The restored vault has a different DEK — the biometric stash for the
      // old one must not survive. Attachment files are not in backups, so
      // clear the now-orphaned directory too.
      await ref.read(secureStoreProvider).deleteDek();
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, 'attachments'));
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    },
  );
});
