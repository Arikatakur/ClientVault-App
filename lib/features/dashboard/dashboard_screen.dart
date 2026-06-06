import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import '../../data/providers/database_provider.dart';
import '../payments/payment_status.dart';
import '../vault/vault_controller.dart';
import 'widgets/stat_card.dart';

/// At-a-glance overview. Numbers are placeholders for now except the live
/// client count, which proves the database → Riverpod → UI path end to end.
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
      data: (list) => list
          .where((p) => p.status != PaymentStatus.paid.value)
          .fold<double>(0, (sum, p) => sum + p.amount),
      orElse: () => 0.0,
    );
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
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
                  value: '$activeProjects',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatCard(
                  icon: Icons.people_alt_outlined,
                  label: 'Clients',
                  value: '$clientCount',
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
                  value: formatMoney(outstanding, 'USD'),
                  accent: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatCard(
                  icon: Icons.lock_outline,
                  label: 'Vault items',
                  value: '$vaultCount',
                  accent: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Recent activity', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  const Icon(
                    Icons.bolt_outlined,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Activity from payments, repos, and vault items will '
                      'appear here.',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
