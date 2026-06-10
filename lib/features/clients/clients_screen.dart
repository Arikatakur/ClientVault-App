import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/local/app_database.dart';
import '../../data/providers/database_provider.dart';
import '../../shared/widgets/empty_state.dart';
import 'widgets/client_form_sheet.dart';

/// Clients list, wired to the on-device database. Searchable by name or
/// company; tap a row to open the client's detail screen, FAB to add one.
class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
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

  bool _matches(Client client) {
    if (_query.isEmpty) return true;
    return client.name.toLowerCase().contains(_query) ||
        (client.company?.toLowerCase().contains(_query) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsStreamProvider);
    final textTheme = Theme.of(context).textTheme;

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
          final filtered = clients.where(_matches).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Search by name or company',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ),
              if (filtered.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No clients match "$_query".',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(indent: 72),
                    itemBuilder: (context, index) =>
                        _ClientTile(client: filtered[index]),
                  ),
                ),
            ],
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
