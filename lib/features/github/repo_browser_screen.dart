import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../shared/widgets/status_chip.dart';
import 'github_controller.dart';
import 'github_models.dart';

/// Browses a linked repository: recent commits, issues, and pull requests.
class RepoBrowserScreen extends StatelessWidget {
  const RepoBrowserScreen({super.key, required this.fullName});

  final String fullName;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(fullName, overflow: TextOverflow.ellipsis),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Commits'),
              Tab(text: 'Issues'),
              Tab(text: 'Pulls'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CommitsTab(fullName: fullName),
            _IssuesTab(fullName: fullName),
            _PullsTab(fullName: fullName),
          ],
        ),
      ),
    );
  }
}

/// Shared loading/error/empty/list scaffolding for the three tabs.
Widget _asyncList<T>(
  BuildContext context, {
  required AsyncValue<List<T>> async,
  required String emptyText,
  required Widget Function(T item) tile,
}) {
  final textTheme = Theme.of(context).textTheme;
  return async.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (_, _) => Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text('Could not load from GitHub.', style: textTheme.bodyMedium),
      ),
    ),
    data: (items) {
      if (items.isEmpty) {
        return Center(child: Text(emptyText, style: textTheme.bodyMedium));
      }
      return ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 56),
        itemBuilder: (context, index) => tile(items[index]),
      );
    },
  );
}

class _CommitsTab extends ConsumerWidget {
  const _CommitsTab({required this.fullName});

  final String fullName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _asyncList<GitHubCommit>(
      context,
      async: ref.watch(repoCommitsProvider(fullName)),
      emptyText: 'No commits found.',
      tile: (commit) => _CommitTile(commit: commit),
    );
  }
}

class _IssuesTab extends ConsumerWidget {
  const _IssuesTab({required this.fullName});

  final String fullName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _asyncList<GitHubIssue>(
      context,
      async: ref.watch(repoIssuesProvider(fullName)),
      emptyText: 'No issues.',
      tile: (issue) => _IssueTile(issue: issue),
    );
  }
}

class _PullsTab extends ConsumerWidget {
  const _PullsTab({required this.fullName});

  final String fullName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _asyncList<GitHubIssue>(
      context,
      async: ref.watch(repoPullsProvider(fullName)),
      emptyText: 'No pull requests.',
      tile: (pull) => _IssueTile(issue: pull),
    );
  }
}

class _CommitTile extends StatelessWidget {
  const _CommitTile({required this.commit});

  final GitHubCommit commit;

  void _showFull(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(commit.shortSha),
        content: SingleChildScrollView(child: Text(commit.message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = [
      commit.shortSha,
      if (commit.authorName != null) commit.authorName!,
      if (commit.date != null) timeAgo(commit.date!),
    ].join(' · ');
    return ListTile(
      leading: const CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.accentSoft,
        child: Icon(Icons.commit, size: 18, color: AppColors.accent),
      ),
      title: Text(commit.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(meta),
      onTap: () => _showFull(context),
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({required this.issue});

  final GitHubIssue issue;

  @override
  Widget build(BuildContext context) {
    final isOpen = issue.state == 'open';
    final color = issue.draft
        ? AppColors.textTertiary
        : isOpen
        ? AppColors.success
        : AppColors.accent;
    final label = issue.draft
        ? 'Draft'
        : isOpen
        ? 'Open'
        : 'Closed';
    final meta = [
      '#${issue.number}',
      if (issue.authorLogin != null) 'by ${issue.authorLogin}',
      if (issue.createdAt != null) timeAgo(issue.createdAt!),
    ].join(' · ');
    return ListTile(
      leading: Icon(
        issue.isPullRequest ? Icons.merge_type : Icons.error_outline,
        color: color,
      ),
      title: Text(issue.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(meta),
      trailing: StatusChip(label: label, color: color),
    );
  }
}
