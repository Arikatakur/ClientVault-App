import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper over the platform secure store (iOS Keychain / Android
/// Keystore). Currently holds the base64 DEK for biometric unlock; the GitHub
/// OAuth token will live here too (v0.4.0).
class SecureStore {
  SecureStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _dekKey = 'vault_dek_b64';

  Future<void> writeDek(String base64Dek) =>
      _storage.write(key: _dekKey, value: base64Dek);

  Future<String?> readDek() => _storage.read(key: _dekKey);

  Future<void> deleteDek() => _storage.delete(key: _dekKey);

  Future<bool> hasDek() => _storage.containsKey(key: _dekKey);
}
