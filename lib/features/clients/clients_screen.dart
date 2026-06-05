import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/local/app_database.dart';
import '../../data/providers/database_provider.dart';
import '../../shared/widgets/empty_state.dart';
import 'widgets/client_form_sheet.dart';

/// Clients list, wired to the on-device database. Tap a row to open the
/// client's detail screen; use the FAB to add one.
class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showClientFormSheet(context, ref),
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
}

class _ClientTile extends StatelessWidget {
  const _ClientTile({required this.client});

  final Client client;

  @override
  Widget build(BuildContext context) {
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
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: () => context.push('/clients/${client.id}'),
    );
  }
}
