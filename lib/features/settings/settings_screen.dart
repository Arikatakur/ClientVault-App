import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../github/github_controller.dart';
import '../vault/vault_controller.dart';
import '../vault/widgets/change_master_password_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final github = ref.watch(githubControllerProvider);
    final githubSubtitle = switch (github.status) {
      GitHubStatus.connected => '@${github.user?.login ?? ''}',
      GitHubStatus.loading => 'Checking…',
      _ => 'Not connected',
    };
    final vaultStatus = ref.watch(vaultControllerProvider);
    final lockTimeout = ref.watch(lockTimeoutProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Security'),
          ListTile(
            leading: const Icon(Icons.timer_outlined, color: AppColors.textSecondary),
            title: const Text('Auto-lock'),
            subtitle: Text(_timeoutLabel(lockTimeout)),
            onTap: () => _pickTimeout(context, ref),
          ),
          ListTile(
            leading: const Icon(
              Icons.password_outlined,
              color: AppColors.textSecondary,
            ),
            title: const Text('Change master password'),
            onTap: () => _changePassword(context, vaultStatus),
          ),
          const _SectionHeader('Integrations'),
          ListTile(
            leading: const Icon(Icons.code, color: AppColors.textSecondary),
            title: const Text('GitHub'),
            subtitle: Text(githubSubtitle),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
            ),
            onTap: () => context.push('/github'),
          ),
          const _SectionHeader('Data'),
          const _SoonTile(
            icon: Icons.backup_outlined,
            title: 'Export encrypted backup',
          ),
          const _SoonTile(icon: Icons.restore_outlined, title: 'Import backup'),
          const _SectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline, color: AppColors.textSecondary),
            title: Text('Version'),
            trailing: Text(
              '0.8.0',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

String _timeoutLabel(int seconds) => switch (seconds) {
  0 => 'Immediately',
  60 => 'After 1 minute',
  300 => 'After 5 minutes',
  _ => 'After ${seconds}s',
};

Future<void> _pickTimeout(BuildContext context, WidgetRef ref) async {
  final current = ref.read(lockTimeoutProvider);
  final choice = await showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in const [0, 60, 300])
            ListTile(
              title: Text(_timeoutLabel(option)),
              trailing: option == current
                  ? const Icon(Icons.check, color: AppColors.accent)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(option),
            ),
        ],
      ),
    ),
  );
  if (choice != null) {
    await ref.read(lockTimeoutProvider.notifier).set(choice);
  }
}

void _changePassword(BuildContext context, VaultStatus status) {
  switch (status) {
    case VaultStatus.locked:
    case VaultStatus.unlocked:
      showChangeMasterPasswordSheet(context);
    case VaultStatus.uninitialized:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set up your vault first.')),
      );
    case VaultStatus.loading:
    case VaultStatus.unavailable:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The vault is available on-device.')),
      );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SoonTile extends StatelessWidget {
  const _SoonTile({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title),
      trailing: const _SoonChip(),
    );
  }
}

class _SoonChip extends StatelessWidget {
  const _SoonChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: const Text(
        'Soon',
        style: TextStyle(
          color: AppColors.accent,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
