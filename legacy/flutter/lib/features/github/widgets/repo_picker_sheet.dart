import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../github_controller.dart';
import '../github_models.dart';

/// Bottom sheet that lists the connected account's repositories and returns
/// the one the user taps (or null if dismissed).
Future<GitHubRepo?> showRepoPickerSheet(BuildContext context) {
  return showModalBottomSheet<GitHubRepo>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _RepoPicker(),
  );
}

class _RepoPicker extends ConsumerStatefulWidget {
  const _RepoPicker();

  @override
  ConsumerState<_RepoPicker> createState() => _RepoPickerState();
}

class _RepoPickerState extends ConsumerState<_RepoPicker> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(
      () => setState(() => _query = _search.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reposAsync = ref.watch(githubReposProvider);
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          0,
        ),
        child: Column(
          children: [
            Text('Link a repository', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search repositories',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: reposAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: Text(
                    'Could not load repositories.',
                    style: textTheme.bodyMedium,
                  ),
                ),
                data: (repos) {
                  if (repos.isEmpty) {
                    return Center(
                      child: Text(
                        'No repositories found.',
                        style: textTheme.bodyMedium,
                      ),
                    );
                  }
                  final filtered = _query.isEmpty
                      ? repos
                      : repos
                            .where(
                              (r) => r.fullName.toLowerCase().contains(_query),
                            )
                            .toList();
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text('No matches.', style: textTheme.bodyMedium),
                    );
                  }
                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final repo = filtered[index];
                      return ListTile(
                        leading: Icon(
                          repo.isPrivate
                              ? Icons.lock_outline
                              : Icons.public_outlined,
                          color: AppColors.textSecondary,
                        ),
                        title: Text(repo.name),
                        subtitle: Text(repo.fullName),
                        onTap: () => Navigator.of(context).pop(repo),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
