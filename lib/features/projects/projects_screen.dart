import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../data/local/app_database.dart';
import '../../data/providers/database_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/status_chip.dart';
import 'project_status.dart';
import 'widgets/project_form_sheet.dart';

/// Projects list across all clients. Tap a row for detail; the FAB creates a
/// project (and nudges the user to add a client first if none exist).
class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsStreamProvider);
    final clientsAsync = ref.watch(clientsStreamProvider);
    final clientsById = {
      for (final client in clientsAsync.value ?? const <Client>[])
        client.id: client,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showProjectFormSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add project'),
      ),
      body: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Database runs on-device',
          message:
              'The encrypted local database is available on iOS and Android. '
              'Run on a device or emulator to add and view projects.',
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return const EmptyState(
              icon: Icons.folder_open_outlined,
              title: 'No projects yet',
              message:
                  'Create a project to track budgets, status, due dates, and '
                  'linked GitHub repos for a client.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: projects.length,
            separatorBuilder: (_, _) => const Divider(indent: 72),
            itemBuilder: (context, index) {
              final project = projects[index];
              return _ProjectTile(
                project: project,
                clientName: clientsById[project.clientId]?.name,
              );
            },
          );
        },
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project, this.clientName});

  final Project project;
  final String? clientName;

  @override
  Widget build(BuildContext context) {
    final status = ProjectStatus.fromValue(project.status);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: status.color.withValues(alpha: 0.16),
        child: Icon(Icons.folder_outlined, color: status.color),
      ),
      title: Text(project.name),
      subtitle: Text(
        clientName ?? 'Unassigned',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          StatusChip(label: status.label, color: status.color),
          if (project.budget != null) ...[
            const SizedBox(height: 4),
            Text(
              formatMoney(project.budget!, project.currency),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      onTap: () => context.push('/projects/${project.id}'),
    );
  }
}
