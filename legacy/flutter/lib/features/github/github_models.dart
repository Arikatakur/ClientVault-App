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

/// A single commit, trimmed to what the commit browser shows.
class GitHubCommit {
  const GitHubCommit({
    required this.sha,
    required this.message,
    this.authorName,
    this.date,
  });

  final String sha;
  final String message;
  final String? authorName;
  final DateTime? date;

  String get shortSha => sha.length >= 7 ? sha.substring(0, 7) : sha;

  /// The first line of the message (the commit summary).
  String get summary {
    final newline = message.indexOf('\n');
    return newline == -1 ? message : message.substring(0, newline);
  }

  factory GitHubCommit.fromJson(Map<String, dynamic> json) {
    final commit = json['commit'] as Map<String, dynamic>?;
    final author = commit?['author'] as Map<String, dynamic>?;
    final date = author?['date'] as String?;
    return GitHubCommit(
      sha: json['sha'] as String? ?? '',
      message: commit?['message'] as String? ?? '',
      authorName: author?['name'] as String?,
      date: date == null ? null : DateTime.tryParse(date),
    );
  }
}

/// An issue or pull request (GitHub treats both as "issues").
class GitHubIssue {
  const GitHubIssue({
    required this.number,
    required this.title,
    required this.state,
    required this.isPullRequest,
    this.authorLogin,
    this.comments = 0,
    this.draft = false,
    this.createdAt,
  });

  final int number;
  final String title;

  /// `open` or `closed`.
  final String state;
  final bool isPullRequest;
  final String? authorLogin;
  final int comments;
  final bool draft;
  final DateTime? createdAt;

  factory GitHubIssue.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final created = json['created_at'] as String?;
    return GitHubIssue(
      number: (json['number'] as num).toInt(),
      title: json['title'] as String? ?? '',
      state: json['state'] as String? ?? 'open',
      isPullRequest: json.containsKey('pull_request') || json['draft'] != null,
      authorLogin: user?['login'] as String?,
      comments: (json['comments'] as num?)?.toInt() ?? 0,
      draft: json['draft'] as bool? ?? false,
      createdAt: created == null ? null : DateTime.tryParse(created),
    );
  }
}
