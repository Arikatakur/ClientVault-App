import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../github/github_controller.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Security'),
          const _SoonTile(
            icon: Icons.timer_outlined,
            title: 'Auto-lock timeout',
          ),
          const _SoonTile(
            icon: Icons.password_outlined,
            title: 'Change master password',
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
              '0.4.0',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
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
