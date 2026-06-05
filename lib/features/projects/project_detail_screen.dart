import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../data/local/app_database.dart';
import '../../data/providers/database_provider.dart';
import '../../shared/widgets/status_chip.dart';
import 'project_status.dart';
import 'widgets/project_form_sheet.dart';

/// Full details for one project. Reached via `/projects/:id`, pushed over the
/// tab shell.
class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectByIdProvider(projectId));

    return projectAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This project is unavailable.')),
      ),
      data: (project) {
        if (project == null) {
          return Scaffold(appBar: AppBar());
        }
        return _ProjectDetailView(project: project);
      },
    );
  }
}

class _ProjectDetailView extends ConsumerWidget {
  const _ProjectDetailView({required this.project});

  final Project project;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text('This permanently deletes ${project.name}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(databaseProvider).deleteProject(project.id);
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ProjectStatus.fromValue(project.status);
    final clientAsync = ref.watch(clientByIdProvider(project.clientId));
    final clientName = clientAsync.value?.name ?? 'Unassigned';
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit project',
            onPressed: () =>
                showProjectFormSheet(context, ref, existing: project),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete project',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(project.name, style: textTheme.headlineSmall),
              ),
              StatusChip(label: status.label, color: status.color),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.person_outline,
                color: AppColors.textSecondary,
              ),
              title: Text(clientName),
              subtitle: const Text('Client'),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
              ),
              onTap: () => context.push('/clients/${project.clientId}'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Budget',
            value: project.budget != null
                ? formatMoney(project.budget!, project.currency)
                : 'Not set',
          ),
          _DetailRow(
            icon: Icons.event_outlined,
            label: 'Due date',
            value: project.dueDate != null
                ? formatDate(project.dueDate!)
                : 'Not set',
          ),
          _DetailRow(
            icon: Icons.schedule_outlined,
            label: 'Created',
            value: formatDate(project.createdAt),
          ),
          if (project.description != null) ...[
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Description', style: textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(project.description!, style: textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
