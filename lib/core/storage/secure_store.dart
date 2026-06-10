import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper over the platform secure store (iOS Keychain / Android
/// Keystore). Holds the base64 DEK for biometric vault unlock and the GitHub
/// personal access token — neither of which belongs in the database.
class SecureStore {
  SecureStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _dekKey = 'vault_dek_b64';
  static const String _dekHwBoundKey = 'vault_dek_hw_bound';
  static const String _githubTokenKey = 'github_token';
  static const String _lockTimeoutKey = 'lock_timeout_seconds';
  static const String _notifEnabledKey = 'notif_enabled';
  static const String _notifLeadDaysKey = 'notif_lead_days';

  /// Keychain policy for the DEK entry: device-bound, and readable only after
  /// the OS verifies the *currently enrolled* Face ID / Touch ID set — so a
  /// newly enrolled face or fingerprint can never open the vault. Android
  /// keeps the app-layer gate until its native biometric wiring lands.
  static const IOSOptions _dekIosOptions = IOSOptions(
    accessibility: KeychainAccessibility.unlocked_this_device,
    accessControlFlags: [AccessControlFlag.biometryCurrentSet],
  );

  // --- Vault DEK (biometric unlock) ------------------------------------------

  Future<void> writeDek(String base64Dek) async {
    // The keychain cannot change an existing item's access policy in place
    // (SecItemUpdate keeps the old one) — recreate the entry instead.
    await _storage.delete(key: _dekKey);
    await _storage.write(
      key: _dekKey,
      value: base64Dek,
      iOptions: _dekIosOptions,
    );
    await _storage.write(key: _dekHwBoundKey, value: 'true');
  }

  /// On iOS, reading a hardware-bound entry triggers the system Face ID /
  /// Touch ID prompt. Returns null when authentication is cancelled or fails,
  /// or when the entry was invalidated by re-enrolled biometrics.
  Future<String?> readDek() async {
    try {
      final bound = await isDekHardwareBound();
      return await _storage.read(
        key: _dekKey,
        iOptions: bound ? _dekIosOptions : null,
      );
    } on Exception {
      return null;
    }
  }

  Future<void> deleteDek() async {
    await _storage.delete(key: _dekKey);
    await _storage.delete(key: _dekHwBoundKey);
  }

  /// Marker first: querying the gated entry itself could prompt for Face ID.
  Future<bool> hasDek() async =>
      await isDekHardwareBound() || await _storage.containsKey(key: _dekKey);

  /// Whether the stashed DEK is under the OS biometric policy. False for
  /// stashes written before v0.11.0, which were gated only in the app layer;
  /// those are upgraded by the vault controller on the next unlock.
  Future<bool> isDekHardwareBound() =>
      _storage.containsKey(key: _dekHwBoundKey);

  // --- GitHub token ----------------------------------------------------------

  Future<void> writeGithubToken(String token) =>
      _storage.write(key: _githubTokenKey, value: token);

  Future<String?> readGithubToken() => _storage.read(key: _githubTokenKey);

  Future<void> deleteGithubToken() => _storage.delete(key: _githubTokenKey);

  // --- Preferences -----------------------------------------------------------

  Future<void> writeLockTimeout(int seconds) =>
      _storage.write(key: _lockTimeoutKey, value: '$seconds');

  Future<int> readLockTimeout() async {
    final value = await _storage.read(key: _lockTimeoutKey);
    return int.tryParse(value ?? '') ?? 0;
  }

  /// Whether due-date reminders are enabled. Defaults to `true` (opt-out).
  Future<bool> readNotifEnabled() async {
    final value = await _storage.read(key: _notifEnabledKey);
    return value == null ? true : value == 'true';
  }

  Future<void> writeNotifEnabled(bool enabled) =>
      _storage.write(key: _notifEnabledKey, value: '$enabled');

  /// How many days before a due date to remind. Defaults to 1.
  Future<int> readNotifLeadDays() async {
    final value = await _storage.read(key: _notifLeadDaysKey);
    return int.tryParse(value ?? '') ?? 1;
  }

  Future<void> writeNotifLeadDays(int days) =>
      _storage.write(key: _notifLeadDaysKey, value: '$days');
}
