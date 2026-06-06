import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/secure_store.dart';
import '../../core/storage/secure_store_provider.dart';
import 'github_client.dart';
import 'github_models.dart';

enum GitHubStatus { loading, disconnected, connected, error }

/// Connection state for the GitHub integration.
class GitHubState {
  const GitHubState({required this.status, this.user, this.error});

  final GitHubStatus status;
  final GitHubUser? user;
  final String? error;
}

final githubControllerProvider =
    NotifierProvider<GitHubController, GitHubState>(GitHubController.new);

/// The connected account's repositories (empty until connected).
final githubReposProvider = FutureProvider<List<GitHubRepo>>((ref) async {
  final state = ref.watch(githubControllerProvider);
  if (state.status != GitHubStatus.connected) {
    return const <GitHubRepo>[];
  }
  return ref.read(githubControllerProvider.notifier).repositories();
});

/// Live status for one repository, keyed by "owner/name".
final repoStatusProvider = FutureProvider.family<GitHubRepo, String>((
  ref,
  fullName,
) {
  return ref.read(githubControllerProvider.notifier).repository(fullName);
});

/// Recent commits for one repository, keyed by "owner/name".
final repoCommitsProvider = FutureProvider.family<List<GitHubCommit>, String>((
  ref,
  fullName,
) {
  return ref.read(githubControllerProvider.notifier).commits(fullName);
});

/// Owns the GitHub token (in secure storage) and the live client.
class GitHubController extends Notifier<GitHubState> {
  GitHubClient? _client;
  late SecureStore _secure;

  @override
  GitHubState build() {
    _secure = ref.watch(secureStoreProvider);
    _restore();
    return const GitHubState(status: GitHubStatus.loading);
  }

  Future<void> _restore() async {
    try {
      final token = await _secure.readGithubToken();
      if (token == null) {
        state = const GitHubState(status: GitHubStatus.disconnected);
        return;
      }
      final client = GitHubClient(token);
      final user = await client.currentUser();
      _client = client;
      state = GitHubState(status: GitHubStatus.connected, user: user);
    } catch (_) {
      // Token missing/invalid, or secure storage unavailable (web preview).
      state = const GitHubState(status: GitHubStatus.disconnected);
    }
  }

  /// Validates [token] against GitHub and, on success, persists + connects.
  /// Keeps the current state during the call so the connect form stays visible
  /// (its button shows the busy spinner); only success/failure changes state.
  Future<bool> connect(String token) async {
    final trimmed = token.trim();
    final client = GitHubClient(trimmed);
    try {
      final user = await client.currentUser();
      await _secure.writeGithubToken(trimmed);
      _client = client;
      state = GitHubState(status: GitHubStatus.connected, user: user);
      return true;
    } on GitHubException catch (e) {
      _client = null;
      state = GitHubState(status: GitHubStatus.error, error: e.message);
      return false;
    }
  }

  Future<void> disconnect() async {
    await _secure.deleteGithubToken();
    _client = null;
    state = const GitHubState(status: GitHubStatus.disconnected);
  }

  Future<List<GitHubRepo>> repositories() {
    final client = _client;
    if (client == null) return Future.value(const <GitHubRepo>[]);
    return client.repositories();
  }

  Future<GitHubRepo> repository(String fullName) {
    final client = _client;
    if (client == null) {
      throw const GitHubException('Connect GitHub to view repository status.');
    }
    return client.repository(fullName);
  }

  Future<List<GitHubCommit>> commits(String fullName) {
    final client = _client;
    if (client == null) {
      throw const GitHubException('Connect GitHub to view commits.');
    }
    return client.commits(fullName);
  }
}
