import 'account_models.dart';

/// Contract every identity backend implements. The app talks only to this —
/// swapping the on-device implementation for Cognito (Amplify) later is a
/// provider rebind, not a refactor.
abstract class AuthRepository {
  /// Whether accounts live in the cloud (false = on-device local mode).
  bool get isCloud;

  /// Returns the persisted session's user, or null when signed out.
  Future<AppUser?> restoreSession();

  Future<AppUser> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signInWithApple();

  Future<AppUser> signInWithGoogle();

  /// Ends the session but keeps the account.
  Future<void> signOut();

  /// Permanently removes the account (Apple requires this in-app once
  /// accounts exist). App data (clients, projects, vault) is not touched.
  Future<void> deleteAccount();
}
