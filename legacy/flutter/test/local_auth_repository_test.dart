import 'package:clientvault/core/crypto/crypto_service.dart';
import 'package:clientvault/core/storage/secure_store.dart';
import 'package:clientvault/features/account/account_models.dart';
import 'package:clientvault/features/account/local_auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

// Cheap Argon2id so the suite stays fast; production uses KdfParams.defaults.
const _testKdf = KdfParams(memory: 64, iterations: 1, parallelism: 1);

LocalAuthRepository _repository() => LocalAuthRepository(
  SecureStore(const FlutterSecureStorage()),
  CryptoService(),
  kdfParams: _testKdf,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
  });

  group('LocalAuthRepository', () {
    test('signUp creates the account and starts a session', () async {
      final repo = _repository();
      final user = await repo.signUp(
        email: '  Saleem@Example.com ',
        password: 'correct horse',
        displayName: 'Saleem',
      );

      expect(user.email, 'saleem@example.com'); // normalized
      expect(user.provider, AuthProviderKind.local);
      expect((await repo.restoreSession())?.id, user.id);
    });

    test(
      'signIn succeeds with the right password and fails with a wrong one',
      () async {
        final repo = _repository();
        await repo.signUp(email: 'a@b.co', password: 'correct horse');
        await repo.signOut();
        expect(await repo.restoreSession(), isNull);

        final user = await repo.signIn(
          email: 'a@b.co',
          password: 'correct horse',
        );
        expect(user.email, 'a@b.co');

        expect(
          () => repo.signIn(email: 'a@b.co', password: 'wrong horse'),
          throwsA(isA<AuthException>()),
        );
      },
    );

    test('only one local account per device', () async {
      final repo = _repository();
      await repo.signUp(email: 'a@b.co', password: 'correct horse');
      expect(
        () => repo.signUp(email: 'c@d.co', password: 'correct horse'),
        throwsA(isA<AuthException>()),
      );
    });

    test('rejects malformed emails and short passwords', () async {
      final repo = _repository();
      expect(
        () => repo.signUp(email: 'not-an-email', password: 'long enough'),
        throwsA(isA<AuthException>()),
      );
      expect(
        () => repo.signUp(email: 'a@b.co', password: 'short'),
        throwsA(isA<AuthException>()),
      );
    });

    test(
      'deleteAccount clears the record so a new account can be created',
      () async {
        final repo = _repository();
        await repo.signUp(email: 'a@b.co', password: 'correct horse');
        await repo.deleteAccount();
        expect(await repo.restoreSession(), isNull);

        // No record left — sign-up works again.
        await repo.signUp(email: 'new@b.co', password: 'correct horse');
      },
    );

    test(
      'Apple and Google sign-in surface the cloud-pending message',
      () async {
        final repo = _repository();
        expect(repo.signInWithApple, throwsA(isA<AuthException>()));
        expect(repo.signInWithGoogle, throwsA(isA<AuthException>()));
      },
    );
  });
}
