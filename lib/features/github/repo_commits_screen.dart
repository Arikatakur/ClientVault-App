import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import 'github_controller.dart';
import 'github_models.dart';

/// Browses recent commits for a linked repository. Tap a commit to read its
/// full message.
class RepoCommitsScreen extends ConsumerWidget {
  const RepoCommitsScreen({super.key, required this.fullName});

  final String fullName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commitsAsync = ref.watch(repoCommitsProvider(fullName));
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commits'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              bottom: AppSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(fullName, style: textTheme.bodySmall),
            ),
          ),
        ),
      ),
      body: commitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Could not load commits.',
              style: textTheme.bodyMedium,
            ),
          ),
        ),
        data: (commits) {
          if (commits.isEmpty) {
            return Center(
              child: Text('No commits found.', style: textTheme.bodyMedium),
            );
          }
          return ListView.separated(
            itemCount: commits.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 56),
            itemBuilder: (context, index) =>
                _CommitTile(commit: commits[index]),
          );
        },
      ),
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
      title: Text(
        commit.summary,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(meta),
      onTap: () => _showFull(context),
    );
  }
}
