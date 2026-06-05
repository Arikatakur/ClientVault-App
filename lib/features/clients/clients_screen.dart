import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/id.dart';
import '../../data/local/app_database.dart';
import '../../data/providers/database_provider.dart';
import '../../shared/widgets/empty_state.dart';

/// Clients list with create + delete, wired to the on-device database.
class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClientSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add client'),
      ),
      body: clientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Database runs on-device',
          message:
              'The encrypted local database is available on iOS and Android. '
              'Run on a device or emulator to add and view clients.',
        ),
        data: (clients) {
          if (clients.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              title: 'No clients yet',
              message:
                  'Add your first client to start organizing projects, '
                  'payments, and credentials around them.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: clients.length,
            separatorBuilder: (_, _) => const Divider(indent: 72),
            itemBuilder: (context, index) =>
                _ClientTile(client: clients[index]),
          );
        },
      ),
    );
  }

  Future<void> _showAddClientSheet(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final companyController = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.sm,
            bottom:
                MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'New client',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Acme Studios',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: companyController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Company (optional)',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(true),
                child: const Text('Save client'),
              ),
            ],
          ),
        );
      },
    );

    final name = nameController.text.trim();
    if (saved == true && name.isNotEmpty) {
      final company = companyController.text.trim();
      final now = DateTime.now();
      await ref
          .read(databaseProvider)
          .insertClient(
            ClientsCompanion.insert(
              id: newId(),
              name: name,
              company: Value(company.isEmpty ? null : company),
              createdAt: now,
              updatedAt: now,
            ),
          );
    }

    nameController.dispose();
    companyController.dispose();
  }
}

class _ClientTile extends ConsumerWidget {
  const _ClientTile({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = client.name.trim();
    final initials = name.isEmpty
        ? '?'
        : name
              .split(RegExp(r'\s+'))
              .take(2)
              .map((word) => word[0].toUpperCase())
              .join();

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.accentSoft,
        child: Text(
          initials,
          style: const TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(client.name),
      subtitle: client.company != null ? Text(client.company!) : null,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        color: AppColors.textTertiary,
        tooltip: 'Delete client',
        onPressed: () => ref.read(databaseProvider).deleteClient(client.id),
      ),
    );
  }
}
