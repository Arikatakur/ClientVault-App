import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../vault_controller.dart';
import '../vault_item_type.dart';
import 'vault_reveal_sheet.dart';

/// "Vault" section on a client/project detail screen: the items linked to it,
/// titles only. Revealing one still requires the vault to be unlocked.
class LinkedVaultSection extends ConsumerWidget {
  const LinkedVaultSection({super.key, this.clientId, this.projectId})
    : assert(
        (clientId != null) ^ (projectId != null),
        'Pass exactly one of clientId / projectId',
      );

  final String? clientId;
  final String? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = clientId != null
        ? ref.watch(vaultItemsForClientProvider(clientId!))
        : ref.watch(vaultItemsForProjectProvider(projectId!));
    final items = itemsAsync.value ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    final unlocked = ref.watch(vaultControllerProvider) == VaultStatus.unlocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Text('Vault', style: textTheme.titleMedium),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              unlocked ? Icons.lock_open_outlined : Icons.lock_outline,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 56),
                ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.accentSoft,
                    child: Icon(
                      VaultItemType.fromValue(items[i].type).icon,
                      size: 18,
                      color: AppColors.accent,
                    ),
                  ),
                  title: Text(items[i].title),
                  subtitle: Text(VaultItemType.fromValue(items[i].type).label),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiary,
                  ),
                  dense: true,
                  onTap: () {
                    if (unlocked) {
                      showVaultRevealSheet(context, items[i]);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Unlock the vault (Vault tab) to reveal this item.',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
