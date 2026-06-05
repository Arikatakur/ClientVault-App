import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/empty_state.dart';
import 'vault_controller.dart';
import 'widgets/vault_lock_view.dart';
import 'widgets/vault_setup_view.dart';
import 'widgets/vault_unlocked_view.dart';

/// Entry point for the Vault tab. Renders the right surface for the current
/// [VaultStatus] and auto-locks the vault whenever the app is backgrounded.
class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      ref.read(vaultControllerProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
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
