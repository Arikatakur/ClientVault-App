import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/local/app_database.dart';
import '../../../shared/widgets/empty_state.dart';
import '../vault_controller.dart';
import '../vault_item_type.dart';
import 'vault_item_form_sheet.dart';
import 'vault_reveal_sheet.dart';

/// The unlocked vault: a searchable list of items, plus lock and biometric
/// controls. Items are listed by title only; nothing is decrypted until tapped.
class VaultUnlockedView extends ConsumerStatefulWidget {
  const VaultUnlockedView({super.key});

  @override
  ConsumerState<VaultUnlockedView> createState() => _VaultUnlockedViewState();
}

class _VaultUnlockedViewState extends ConsumerState<VaultUnlockedView> {
  final _search = TextEditingController();
  String _query = '';
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(
      () => setState(() => _query = _search.text.trim().toLowerCase()),
    );
    _loadBiometric();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadBiometric() async {
    final notifier = ref.read(vaultControllerProvider.notifier);
    final available = await notifier.isBiometricAvailable();
    final enabled = await notifier.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
      });
    }
  }

  Future<void> _toggleBiometric() async {
    final notifier = ref.read(vaultControllerProvider.notifier);
    if (_biometricEnabled) {
      await notifier.disableBiometricUnlock();
    } else {
      await notifier.enableBiometricUnlock();
    }
    await _loadBiometric();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _biometricEnabled
                ? 'Biometric unlock enabled'
                : 'Biometric unlock disabled',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(vaultItemsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault'),
        actions: [
          if (_biometricAvailable)
            IconButton(
              icon: Icon(
                _biometricEnabled
                    ? Icons.fingerprint
                    : Icons.fingerprint_outlined,
              ),
              tooltip: _biometricEnabled
                  ? 'Disable biometric unlock'
                  : 'Enable biometric unlock',
              onPressed: _toggleBiometric,
            ),
          IconButton(
            icon: const Icon(Icons.lock_outline),
            tooltip: 'Lock vault',
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(vaultControllerProvider.notifier).lock();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showVaultItemSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const EmptyState(
          icon: Icons.lock_outline,
          title: 'Vault runs on-device',
          message:
              'The encrypted vault is available on iOS and Android. Run on a '
              'device to store and view credentials.',
        ),
        data: (items) {
          final filtered = _query.isEmpty
              ? items
              : items
                    .where((item) => item.title.toLowerCase().contains(_query))
                    .toList();

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
                    hintText: 'Search by title',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ),
              if (items.isEmpty)
                const Expanded(
                  child: EmptyState(
                    icon: Icons.shield_outlined,
                    title: 'Your vault is empty',
                    message:
                        'Add your first password, API key, or account — every '
                        'item is encrypted on-device with AES-256-GCM.',
                  ),
                )
              else if (filtered.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No items match "$_query".',
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
                        _VaultItemTile(item: filtered[index]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _VaultItemTile extends StatelessWidget {
  const _VaultItemTile({required this.item});

  final VaultItem item;

  @override
  Widget build(BuildContext context) {
    final type = VaultItemType.fromValue(item.type);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.accentSoft,
        child: Icon(type.icon, color: AppColors.accent),
      ),
      title: Text(item.title),
      subtitle: Text(type.label),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: () => showVaultRevealSheet(context, item),
    );
  }
}
