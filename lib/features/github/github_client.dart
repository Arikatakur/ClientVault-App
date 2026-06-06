import 'package:dio/dio.dart';

import 'github_models.dart';

/// Raised for any GitHub API failure, carrying a user-facing [message].
class GitHubException implements Exception {
  const GitHubException(this.message);

  final String message;

  @override
  String toString() => 'GitHubException: $message';
}

/// Minimal, read-only GitHub REST client. Constructed with a personal access
/// token; used for the authenticated user and their repositories.
class GitHubClient {
  GitHubClient(String token, {Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://api.github.com',
              headers: {
                'Accept': 'application/vnd.github+json',
                'X-GitHub-Api-Version': '2022-11-28',
                'Authorization': 'Bearer $token',
              },
              validateStatus: (status) => status != null && status < 300,
            ),
          );

  final Dio _dio;

  Future<GitHubUser> currentUser() async {
    final data = await _get('/user');
    return GitHubUser.fromJson(data as Map<String, dynamic>);
  }

  Future<List<GitHubRepo>> repositories() async {
    final data = await _get(
      '/user/repos',
      query: {
        'per_page': 100,
        'sort': 'updated',
        'affiliation': 'owner,collaborator,organization_member',
      },
    );
    final list = (data as List<dynamic>).cast<Map<String, dynamic>>();
    return list.map(GitHubRepo.fromJson).toList();
  }

  Future<GitHubRepo> repository(String fullName) async {
    final data = await _get('/repos/$fullName');
    return GitHubRepo.fromJson(data as Map<String, dynamic>);
  }

  Future<List<GitHubCommit>> commits(String fullName) async {
    final data = await _get('/repos/$fullName/commits', query: {'per_page': 30});
    final list = (data as List<dynamic>).cast<Map<String, dynamic>>();
    return list.map(GitHubCommit.fromJson).toList();
  }

  Future<dynamic> _get(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await _dio.get<dynamic>(path, queryParameters: query);
      return response.data;
    } on DioException catch (e) {
      throw GitHubException(_messageFor(e));
    }
  }

  String _messageFor(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) return 'Invalid or expired token.';
    if (status == 403) return 'GitHub rate limit reached. Try again later.';
    if (status == 404) return 'Not found on GitHub.';
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Could not reach GitHub. Check your connection.';
    }
    return status == null
        ? 'GitHub request failed.'
        : 'GitHub request failed ($status).';
  }
}
