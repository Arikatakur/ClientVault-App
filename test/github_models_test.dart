// Verifies GitHub JSON parsing (pure, VM-testable).

import 'package:clientvault/features/github/github_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GitHubRepo.fromJson parses the fields ClientVault uses', () {
    final repo = GitHubRepo.fromJson({
      'id': 42,
      'name': 'clientvault',
      'full_name': 'arikatakur/clientvault',
      'private': true,
      'default_branch': 'main',
      'open_issues_count': 3,
      'stargazers_count': 7,
      'html_url': 'https://github.com/arikatakur/clientvault',
      'description': 'Personal command center',
      'language': 'Dart',
      'pushed_at': '2026-06-06T10:00:00Z',
    });

    expect(repo.id, 42);
    expect(repo.fullName, 'arikatakur/clientvault');
    expect(repo.isPrivate, isTrue);
    expect(repo.defaultBranch, 'main');
    expect(repo.openIssues, 3);
    expect(repo.stargazers, 7);
    expect(repo.pushedAt, isNotNull);
  });

  test('GitHubRepo.fromJson tolerates missing optional fields', () {
    final repo = GitHubRepo.fromJson({
      'id': 1,
      'name': 'x',
      'full_name': 'a/x',
    });

    expect(repo.isPrivate, isFalse);
    expect(repo.defaultBranch, 'main');
    expect(repo.openIssues, 0);
    expect(repo.description, isNull);
    expect(repo.pushedAt, isNull);
  });

  test('GitHubUser.fromJson tolerates a missing name', () {
    final user = GitHubUser.fromJson({'login': 'octo', 'avatar_url': 'x'});

    expect(user.login, 'octo');
    expect(user.name, isNull);
    expect(user.avatarUrl, 'x');
  });
}
