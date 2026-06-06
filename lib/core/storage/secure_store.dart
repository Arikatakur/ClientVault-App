import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper over the platform secure store (iOS Keychain / Android
/// Keystore). Holds the base64 DEK for biometric vault unlock and the GitHub
/// personal access token — neither of which belongs in the database.
class SecureStore {
  SecureStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _dekKey = 'vault_dek_b64';
  static const String _githubTokenKey = 'github_token';
  static const String _lockTimeoutKey = 'lock_timeout_seconds';
  static const String _notifEnabledKey = 'notif_enabled';
  static const String _notifLeadDaysKey = 'notif_lead_days';

  // --- Vault DEK (biometric unlock) ------------------------------------------

  Future<void> writeDek(String base64Dek) =>
      _storage.write(key: _dekKey, value: base64Dek);

  Future<String?> readDek() => _storage.read(key: _dekKey);

  Future<void> deleteDek() => _storage.delete(key: _dekKey);

  Future<bool> hasDek() => _storage.containsKey(key: _dekKey);

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
