import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/secure_store_provider.dart';
import '../vault/vault_controller.dart' show cryptoServiceProvider;
import 'account_models.dart';
import 'auth_repository.dart';
import 'local_auth_repository.dart';

enum AccountStatus { loading, signedOut, signedIn }

class AccountState {
  const AccountState(this.status, [this.user]);

  final AccountStatus status;
  final AppUser? user;

  bool get isSignedIn => status == AccountStatus.signedIn && user != null;
}

/// Rebind this to a Cognito-backed repository when the AWS backend lands —
/// nothing above this provider changes.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => LocalAuthRepository(
    ref.watch(secureStoreProvider),
    ref.watch(cryptoServiceProvider),
  ),
);

final accountControllerProvider =
    NotifierProvider<AccountController, AccountState>(AccountController.new);

/// Session state machine. Methods rethrow [AuthException] so screens can show
/// the message; on success the state flips and the session is persisted by
/// the repository.
class AccountController extends Notifier<AccountState> {
  late AuthRepository _repo;

  @override
  AccountState build() {
    _repo = ref.watch(authRepositoryProvider);
    _restore();
    return const AccountState(AccountStatus.loading);
  }

  Future<void> _restore() async {
    final user = await _repo.restoreSession();
    state = user == null
        ? const AccountState(AccountStatus.signedOut)
        : AccountState(AccountStatus.signedIn, user);
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final user = await _repo.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
    state = AccountState(AccountStatus.signedIn, user);
  }

  Future<void> signIn({required String email, required String password}) async {
    final user = await _repo.signIn(email: email, password: password);
    state = AccountState(AccountStatus.signedIn, user);
  }

  Future<void> signInWithApple() async {
    final user = await _repo.signInWithApple();
    state = AccountState(AccountStatus.signedIn, user);
  }

  Future<void> signInWithGoogle() async {
    final user = await _repo.signInWithGoogle();
    state = AccountState(AccountStatus.signedIn, user);
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AccountState(AccountStatus.signedOut);
  }

  Future<void> deleteAccount() async {
    await _repo.deleteAccount();
    state = const AccountState(AccountStatus.signedOut);
  }
}
