import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../data/local/app_database.dart';
import '../../data/providers/database_provider.dart';
import '../payments/payment_status.dart';
import '../vault/vault_controller.dart';
import 'widgets/stat_card.dart';

/// At-a-glance overview with live counts and a recent-activity feed.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(clientsStreamProvider);
    final clientCount = clients.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );
    final projects = ref.watch(projectsStreamProvider);
    final activeProjects = projects.maybeWhen(
      data: (list) => list.where((p) => p.status == 'active').length,
      orElse: () => 0,
    );
    final vaultItems = ref.watch(vaultItemsProvider);
    final vaultCount = vaultItems.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );
    final payments = ref.watch(paymentsStreamProvider);
    final outstanding = payments.maybeWhen(
      data: (list) =>
          list.fold<double>(0, (sum, p) => sum + (p.amount - p.paidAmount)),
      orElse: () => 0.0,
    );
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children:
            <Widget>[
                  Text('Welcome back', style: textTheme.bodyMedium),
                  const SizedBox(height: 2),
                  Text('Your command center', style: textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.folder_open,
                          label: 'Active projects',
                          value: activeProjects.toDouble(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: StatCard(
                          icon: Icons.people_alt_outlined,
                          label: 'Clients',
                          value: clientCount.toDouble(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Outstanding',
                          value: outstanding,
                          format: (v) => formatMoney(v, 'USD'),
                          accent: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: StatCard(
                          icon: Icons.lock_outline,
                          label: 'Vault items',
                          value: vaultCount.toDouble(),
                          accent: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Recent activity', style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  _RecentActivity(
                    clients: clients.value ?? const <Client>[],
                    projects: projects.value ?? const <Project>[],
                    payments: payments.value ?? const <Payment>[],
                    vaultItems: vaultItems.value ?? const <VaultItem>[],
                  ),
                ]
                .animate(interval: 40.ms)
                .fadeIn(duration: 250.ms, curve: Curves.easeOut)
                .slideY(
                  begin: 0.05,
                  end: 0,
                  duration: 250.ms,
                  curve: Curves.easeOut,
                ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({
    required this.clients,
    required this.projects,
    required this.payments,
    required this.vaultItems,
  });

  final List<Client> clients;
  final List<Project> projects;
  final List<Payment> payments;
  final List<VaultItem> vaultItems;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final entries = <_ActivityEntry>[
      for (final c in clients)
        _ActivityEntry(
          time: c.createdAt,
          icon: Icons.person_add_alt,
          title: c.name,
          subtitle: 'Client added',
        ),
      for (final p in projects)
        _ActivityEntry(
          time: p.updatedAt,
          icon: Icons.folder_open,
          title: p.name,
          subtitle: 'Project',
        ),
      for (final p in payments)
        _ActivityEntry(
          time: p.updatedAt,
          icon: Icons.account_balance_wallet_outlined,
          title: formatMoney(p.amount, p.currency),
          subtitle: 'Payment · ${paymentDisplay(p).label}',
        ),
      for (final v in vaultItems)
        _ActivityEntry(
          time: v.updatedAt,
          icon: Icons.lock_outline,
          title: v.title,
          subtitle: 'Vault item',
        ),
    ]..sort((a, b) => b.time.compareTo(a.time));

    if (entries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const Icon(Icons.bolt_outlined, color: AppColors.textTertiary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Add clients, projects, payments, or vault items and your '
                  'recent activity shows up here.',
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final recent = entries.take(6).toList();
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < recent.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 56),
            ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.accentSoft,
                child: Icon(recent[i].icon, size: 18, color: AppColors.accent),
              ),
              title: Text(
                recent[i].title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(recent[i].subtitle),
              trailing: Text(
                timeAgo(recent[i].time),
                style: textTheme.bodySmall,
              ),
              dense: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityEntry {
  const _ActivityEntry({
    required this.time,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final DateTime time;
  final IconData icon;
  final String title;
  final String subtitle;
}
