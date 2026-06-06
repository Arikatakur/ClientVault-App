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
}
