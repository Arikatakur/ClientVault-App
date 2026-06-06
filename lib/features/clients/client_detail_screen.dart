import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../data/local/app_database.dart';
import '../../data/providers/database_provider.dart';
import '../../shared/widgets/status_chip.dart';
import '../attachments/widgets/attachments_section.dart';
import '../projects/project_status.dart';
import '../projects/widgets/project_form_sheet.dart';
import 'widgets/client_form_sheet.dart';

/// Full details for one client: contact info, notes, and their projects.
/// Reached via `/clients/:id`, pushed over the tab shell.
class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientByIdProvider(clientId));

    return clientAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This client is unavailable.')),
      ),
      data: (client) {
        if (client == null) {
          // Deleted (usually from this screen's own delete action, which pops).
          return Scaffold(appBar: AppBar());
        }
        return _ClientDetailView(client: client);
      },
    );
  }
}

class _ClientDetailView extends ConsumerWidget {
  const _ClientDetailView({required this.client});

  final Client client;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete client?'),
        content: Text(
          'This permanently deletes ${client.name} and all of their projects.',
        ),
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
    await ref.read(databaseProvider).deleteClient(client.id);
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(clientProjectsProvider(client.id));
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(client.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit client',
            onPressed: () => showClientFormSheet(context, ref, existing: client),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete client',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _ClientHeader(client: client),
          if (client.email != null || client.phone != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _ContactCard(client: client),
          ],
          if (client.notes != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _NotesCard(notes: client.notes!),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Projects', style: textTheme.titleMedium),
              TextButton.icon(
                onPressed: () => showProjectFormSheet(
                  context,
                  ref,
                  lockedClientId: client.id,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          projectsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Text(
              'Projects are available on-device.',
              style: textTheme.bodyMedium,
            ),
            data: (projects) {
              if (projects.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'No projects yet for this client.',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final project in projects)
                    _ClientProjectTile(project: project),
                ],
              );
            },
          ),
          AttachmentsSection(clientId: client.id),
        ],
      ),
    );
  }
}

class _ClientHeader extends StatelessWidget {
  const _ClientHeader({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = client.name.trim();
    final initials = name.isEmpty
        ? '?'
        : name
              .split(RegExp(r'\s+'))
              .take(2)
              .map((word) => word[0].toUpperCase())
              .join();
    final isArchived = client.status == 'archived';

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.accentSoft,
          child: Text(
            initials,
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(client.name, style: textTheme.titleLarge),
              if (client.company != null) ...[
                const SizedBox(height: 2),
                Text(client.company!, style: textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        StatusChip(
          label: isArchived ? 'Archived' : 'Active',
          color: isArchived ? AppColors.textTertiary : AppColors.success,
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          if (client.email != null)
            ListTile(
              leading: const Icon(
                Icons.email_outlined,
                color: AppColors.textSecondary,
              ),
              title: Text(client.email!),
              dense: true,
            ),
          if (client.phone != null)
            ListTile(
              leading: const Icon(
                Icons.phone_outlined,
                color: AppColors.textSecondary,
              ),
              title: Text(client.phone!),
              dense: true,
            ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notes', style: textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(notes, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ClientProjectTile extends StatelessWidget {
  const _ClientProjectTile({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final status = ProjectStatus.fromValue(project.status);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(Icons.folder_outlined, color: status.color),
        title: Text(project.name),
        subtitle: Text(
          project.budget != null
              ? '${status.label} · ${formatMoney(project.budget!, project.currency)}'
              : status.label,
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textTertiary,
        ),
        onTap: () => context.push('/projects/${project.id}'),
      ),
    );
  }
}
