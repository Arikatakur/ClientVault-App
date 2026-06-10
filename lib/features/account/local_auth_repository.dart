import 'dart:convert';

import '../../core/crypto/crypto_service.dart';
import '../../core/storage/secure_store.dart';
import '../../core/utils/id.dart';
import 'account_models.dart';
import 'auth_repository.dart';

/// On-device account backend used until the AWS (Cognito) backend exists.
/// One account per device; the password is never stored — only its Argon2id
/// hash (same KDF family the vault uses, independent salt and key).
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(
    this._secure,
    this._crypto, {
    this.kdfParams = KdfParams.defaults,
  });

  final SecureStore _secure;
  final CryptoService _crypto;

  /// Tests pass cheap parameters; production keeps the Argon2id defaults.
  final KdfParams kdfParams;

  static const String _cloudPendingMessage =
      'Sign-in with this provider goes live with the ClientVault Cloud '
      'release. Until then, accounts stay on this device.';

  @override
  bool get isCloud => false;

  @override
  Future<AppUser?> restoreSession() async {
    final session = await _secure.readAccountSession();
    if (session == null) return null;
    try {
      return AppUser.fromJsonString(session);
    } on FormatException {
      await _secure.deleteAccountSession();
      return null;
    }
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final normalized = _normalizeEmail(email);
    _validateEmail(normalized);
    _validatePassword(password);

    if (await _secure.readAccountRecord() != null) {
      throw const AuthException(
        'An account already exists on this device — sign in instead, or '
        'delete it first from the account screen.',
      );
    }

    final salt = _crypto.newSalt();
    final hash = await _hashPassword(password, salt);
    final user = AppUser(
      id: newId(),
      email: normalized,
      displayName: (displayName?.trim().isEmpty ?? true)
          ? null
          : displayName!.trim(),
      provider: AuthProviderKind.local,
      createdAt: DateTime.now(),
    );

    await _secure.writeAccountRecord(
      jsonEncode({
        'user': user.toJson(),
        'salt': base64Encode(salt),
        'hash': base64Encode(hash),
        'kdfMemory': kdfParams.memory,
        'kdfIterations': kdfParams.iterations,
        'kdfParallelism': kdfParams.parallelism,
      }),
    );
    await _secure.writeAccountSession(user.toJsonString());
    return user;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final raw = await _secure.readAccountRecord();
    if (raw == null) {
      throw const AuthException(
        'No account on this device yet — create one first.',
      );
    }

    final record = jsonDecode(raw) as Map<String, Object?>;
    final user = AppUser.fromJson(record['user']! as Map<String, Object?>);
    if (_normalizeEmail(email) != user.email) {
      throw const AuthException('Email or password is incorrect.');
    }

    final hash = await _hashPassword(
      password,
      base64Decode(record['salt'] as String),
      KdfParams(
        memory: record['kdfMemory'] as int,
        iterations: record['kdfIterations'] as int,
        parallelism: record['kdfParallelism'] as int,
      ),
    );
    if (!_constantTimeEquals(hash, base64Decode(record['hash'] as String))) {
      throw const AuthException('Email or password is incorrect.');
    }

    await _secure.writeAccountSession(user.toJsonString());
    return user;
  }

  @override
  Future<AppUser> signInWithApple() =>
      throw const AuthException(_cloudPendingMessage);

  @override
  Future<AppUser> signInWithGoogle() =>
      throw const AuthException(_cloudPendingMessage);

  @override
  Future<void> signOut() => _secure.deleteAccountSession();

  @override
  Future<void> deleteAccount() async {
    await _secure.deleteAccountSession();
    await _secure.deleteAccountRecord();
  }

  Future<List<int>> _hashPassword(
    String password,
    List<int> salt, [
    KdfParams? params,
  ]) async {
    final key = await _crypto.deriveKek(password, salt, params ?? kdfParams);
    return key.extractBytes();
  }

  static String _normalizeEmail(String email) => email.trim().toLowerCase();

  static void _validateEmail(String email) {
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!valid) throw const AuthException('Enter a valid email address.');
  }

  static void _validatePassword(String password) {
    if (password.length < 8) {
      throw const AuthException('Use at least 8 characters for the password.');
    }
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
