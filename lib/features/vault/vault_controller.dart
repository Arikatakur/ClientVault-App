import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/biometric_auth.dart';
import '../../core/crypto/crypto_service.dart';
import '../../core/storage/secure_store.dart';
import '../../core/utils/id.dart';
import '../../data/local/app_database.dart';
import '../../data/providers/database_provider.dart';
import 'vault_item_type.dart';
import 'vault_payload.dart';

/// Lifecycle of the vault as seen by the UI.
enum VaultStatus { loading, unavailable, uninitialized, locked, unlocked }

final cryptoServiceProvider = Provider<CryptoService>((ref) => CryptoService());
final secureStoreProvider = Provider<SecureStore>((ref) => SecureStore());
final biometricAuthProvider = Provider<BiometricAuth>((ref) => BiometricAuth());

/// Reactive list of vault items (titles/types only — never decrypted here).
final vaultItemsProvider = StreamProvider<List<VaultItem>>((ref) {
  return ref.watch(databaseProvider).watchVaultItems();
});

final vaultControllerProvider = NotifierProvider<VaultController, VaultStatus>(
  VaultController.new,
);

/// Owns the in-memory data key (DEK) and every operation that touches it.
/// Nothing else in the app reads or holds key material.
class VaultController extends Notifier<VaultStatus> {
  SecretKey? _dek; // in-memory data key; null whenever the vault is locked

  late AppDatabase _db;
  late CryptoService _crypto;
  late SecureStore _secure;
  late BiometricAuth _biometric;

  @override
  VaultStatus build() {
    _db = ref.watch(databaseProvider);
    _crypto = ref.watch(cryptoServiceProvider);
    _secure = ref.watch(secureStoreProvider);
    _biometric = ref.watch(biometricAuthProvider);
    ref.onDispose(() => _dek = null);
    _loadStatus();
    return VaultStatus.loading;
  }

  Future<void> _loadStatus() async {
    try {
      final config = await _db.getVaultConfig();
      state = config == null
          ? VaultStatus.uninitialized
          : VaultStatus.locked;
    } catch (_) {
      // No on-device database (e.g. web preview): show the unavailable state.
      state = VaultStatus.unavailable;
    }
  }

  bool get isUnlocked => _dek != null;

  /// Creates the vault: generate a random DEK, derive a KEK from [password],
  /// wrap the DEK, and persist the crypto config. The password is never stored.
  Future<void> setupMasterPassword(String password) async {
    final dek = _crypto.newDataKey();
    final salt = _crypto.newSalt();
    const params = KdfParams.defaults;

    final kek = await _crypto.deriveKek(password, salt, params);
    final dekBytes = await dek.extractBytes();
    final wrapped = await _crypto.seal(dekBytes, kek);

    final now = DateTime.now();
    await _db.saveVaultConfig(
      VaultConfigsCompanion.insert(
        id: vaultConfigId,
        kdfSalt: salt,
        kdfMemory: params.memory,
        kdfIterations: params.iterations,
        kdfParallelism: params.parallelism,
        wrappedDek: Uint8List.fromList(wrapped.cipherText),
        wrappedDekNonce: Uint8List.fromList(wrapped.nonce),
        wrappedDekMac: Uint8List.fromList(wrapped.mac),
        createdAt: now,
        updatedAt: now,
      ),
    );
    _dek = SecretKey(dekBytes);
    state = VaultStatus.unlocked;
  }

  /// Attempts to unlock with [password]; returns false on a wrong password.
  Future<bool> unlock(String password) async {
    final config = await _db.getVaultConfig();
    if (config == null) return false;

    final kek = await _crypto.deriveKek(
      password,
      config.kdfSalt,
      KdfParams(
        memory: config.kdfMemory,
        iterations: config.kdfIterations,
        parallelism: config.kdfParallelism,
      ),
    );
    try {
      final dekBytes = await _crypto.open(
        SealedBytes(
          cipherText: config.wrappedDek,
          nonce: config.wrappedDekNonce,
          mac: config.wrappedDekMac,
        ),
        kek,
      );
      _dek = SecretKey(dekBytes);
      state = VaultStatus.unlocked;
      return true;
    } on SecretBoxAuthenticationError {
      return false; // GCM auth failed => wrong password
    }
  }

  /// Unlocks via biometrics using the DEK stashed in secure storage.
  Future<bool> unlockWithBiometrics() async {
    final ok = await _biometric.authenticate('Unlock your ClientVault');
    if (!ok) return false;
    final base64Dek = await _secure.readDek();
    if (base64Dek == null) return false;
    _dek = SecretKey(base64Decode(base64Dek));
    state = VaultStatus.unlocked;
    return true;
  }

  /// Clears the in-memory key and returns to the locked screen.
  void lock() {
    _dek = null;
    if (state == VaultStatus.unlocked) {
      state = VaultStatus.locked;
    }
  }

  Future<bool> isBiometricEnabled() => _secure.hasDek();

  Future<bool> isBiometricAvailable() => _biometric.isAvailable();

  /// Stashes the current DEK behind the device's biometric lock.
  Future<void> enableBiometricUnlock() async {
    final dek = _dek;
    if (dek == null) return;
    final bytes = await dek.extractBytes();
    await _secure.writeDek(base64Encode(bytes));
  }

  Future<void> disableBiometricUnlock() => _secure.deleteDek();

  // --- Items -----------------------------------------------------------------

  Future<void> addItem({
    required VaultItemType type,
    required String title,
    required VaultPayload payload,
    String? clientId,
    String? projectId,
  }) async {
    final dek = _requireDek();
    final sealed = await _crypto.seal(payload.toBytes(), dek);
    final now = DateTime.now();
    await _db.insertVaultItem(
      VaultItemsCompanion.insert(
        id: newId(),
        type: type.value,
        title: title,
        clientId: Value(clientId),
        projectId: Value(projectId),
        ciphertext: Uint8List.fromList(sealed.cipherText),
        nonce: Uint8List.fromList(sealed.nonce),
        mac: Uint8List.fromList(sealed.mac),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> updateItem({
    required String id,
    required VaultItemType type,
    required String title,
    required VaultPayload payload,
    String? clientId,
    String? projectId,
  }) async {
    final dek = _requireDek();
    final sealed = await _crypto.seal(payload.toBytes(), dek);
    await _db.updateVaultItem(
      id,
      VaultItemsCompanion(
        type: Value(type.value),
        title: Value(title),
        clientId: Value(clientId),
        projectId: Value(projectId),
        ciphertext: Value(Uint8List.fromList(sealed.cipherText)),
        nonce: Value(Uint8List.fromList(sealed.nonce)),
        mac: Value(Uint8List.fromList(sealed.mac)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteItem(String id) => _db.deleteVaultItem(id);

  /// Decrypts one item on demand (lazy-decrypt; the list is never bulk-opened).
  Future<VaultPayload> reveal(VaultItem item) async {
    final dek = _requireDek();
    final bytes = await _crypto.open(
      SealedBytes(
        cipherText: item.ciphertext,
        nonce: item.nonce,
        mac: item.mac,
      ),
      dek,
    );
    return VaultPayload.fromBytes(bytes);
  }

  SecretKey _requireDek() {
    final dek = _dek;
    if (dek == null) {
      throw StateError('Vault is locked');
    }
    return dek;
  }
}
