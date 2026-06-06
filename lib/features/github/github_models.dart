/// The authenticated GitHub account.
class GitHubUser {
  const GitHubUser({required this.login, this.name, this.avatarUrl});

  final String login;
  final String? name;
  final String? avatarUrl;

  factory GitHubUser.fromJson(Map<String, dynamic> json) {
    return GitHubUser(
      login: json['login'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

/// A GitHub repository, trimmed to the fields ClientVault shows.
class GitHubRepo {
  const GitHubRepo({
    required this.id,
    required this.fullName,
    required this.name,
    required this.isPrivate,
    required this.defaultBranch,
    required this.openIssues,
    required this.stargazers,
    required this.htmlUrl,
    this.description,
    this.language,
    this.pushedAt,
  });

  final int id;
  final String fullName;
  final String name;
  final bool isPrivate;
  final String defaultBranch;
  final int openIssues;
  final int stargazers;
  final String htmlUrl;
  final String? description;
  final String? language;
  final DateTime? pushedAt;

  factory GitHubRepo.fromJson(Map<String, dynamic> json) {
    final pushed = json['pushed_at'] as String?;
    return GitHubRepo(
      id: (json['id'] as num).toInt(),
      fullName: json['full_name'] as String,
      name: json['name'] as String,
      isPrivate: json['private'] as bool? ?? false,
      defaultBranch: json['default_branch'] as String? ?? 'main',
      openIssues: (json['open_issues_count'] as num?)?.toInt() ?? 0,
      stargazers: (json['stargazers_count'] as num?)?.toInt() ?? 0,
      htmlUrl: json['html_url'] as String? ?? '',
      description: json['description'] as String?,
      language: json['language'] as String?,
      pushedAt: pushed == null ? null : DateTime.tryParse(pushed),
    );
  }
}
