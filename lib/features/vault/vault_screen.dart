import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/empty_state.dart';
import 'vault_controller.dart';
import 'widgets/vault_lock_view.dart';
import 'widgets/vault_setup_view.dart';
import 'widgets/vault_unlocked_view.dart';

/// Entry point for the Vault tab. Renders the right surface for the current
/// [VaultStatus]. Auto-lock is handled app-wide by `AutoLockScope`.
class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(vaultControllerProvider);
    return switch (status) {
      VaultStatus.loading => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      VaultStatus.unavailable => Scaffold(
        appBar: AppBar(title: const Text('Vault')),
        body: const EmptyState(
          icon: Icons.lock_outline,
          title: 'Vault runs on-device',
          message:
              'The encrypted vault is available on iOS and Android. Run on a '
              'device to set it up and store credentials securely.',
        ),
      ),
      VaultStatus.uninitialized => const VaultSetupView(),
      VaultStatus.locked => const VaultLockView(),
      VaultStatus.unlocked => const VaultUnlockedView(),
    };
  }
}
