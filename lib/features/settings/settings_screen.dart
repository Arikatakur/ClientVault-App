import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../account/account_controller.dart';
import '../backup/backup_flows.dart';
import '../billing/entitlement_controller.dart';
import '../github/github_controller.dart';
import '../notifications/notification_prefs.dart';
import '../notifications/reminder_scheduler.dart';
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
    final notifPrefs = ref.watch(notificationPrefsProvider);

    final account = ref.watch(accountControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Account'),
          ListTile(
            leading: const Icon(
              Icons.account_circle_outlined,
              color: AppColors.textSecondary,
            ),
            title: Text(
              account.isSignedIn
                  ? (account.user!.displayName ?? account.user!.email)
                  : 'Create account or sign in',
            ),
            subtitle: Text(
              account.isSignedIn
                  ? account.user!.email
                  : 'Your identity for cloud sync and subscriptions',
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
            ),
            onTap: () => context.push('/account'),
          ),
          ListTile(
            leading: const Icon(
              Icons.workspace_premium_outlined,
              color: AppColors.textSecondary,
            ),
            title: const Text('Plan'),
            subtitle: Text('${ref.watch(entitlementProvider).tier.label} plan'),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
            ),
            onTap: () => context.push('/plans'),
          ),
          const _SectionHeader('Notifications'),
          SwitchListTile(
            secondary: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.textSecondary,
            ),
            title: const Text('Due-date reminders'),
            subtitle: const Text('Get reminded before payments and deadlines'),
            value: notifPrefs.enabled,
            onChanged: (value) => _setRemindersEnabled(ref, value),
          ),
          ListTile(
            enabled: notifPrefs.enabled,
            leading: const Icon(
              Icons.schedule_outlined,
              color: AppColors.textSecondary,
            ),
            title: const Text('Remind me'),
            subtitle: Text(_leadLabel(notifPrefs.leadDays)),
            onTap: notifPrefs.enabled
                ? () => _pickLeadDays(context, ref)
                : null,
          ),
          ListTile(
            enabled: notifPrefs.enabled,
            leading: const Icon(
              Icons.notification_add_outlined,
              color: AppColors.textSecondary,
            ),
            title: const Text('Send a test notification'),
            onTap: notifPrefs.enabled
                ? () => _sendTestNotification(context, ref)
                : null,
          ),
          const _SoonTile(
            icon: Icons.podcasts_outlined,
            title: 'Push notifications',
            subtitle: 'Repo activity and cross-device alerts, with the cloud',
          ),
          const _SectionHeader('Security'),
          ListTile(
            leading: const Icon(
              Icons.timer_outlined,
              color: AppColors.textSecondary,
            ),
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
          ListTile(
            leading: const Icon(
              Icons.backup_outlined,
              color: AppColors.textSecondary,
            ),
            title: const Text('Export encrypted backup'),
            subtitle: const Text('Everything except attachment files'),
            onTap: () => exportBackupFlow(context, ref),
          ),
          ListTile(
            leading: const Icon(
              Icons.restore_outlined,
              color: AppColors.textSecondary,
            ),
            title: const Text('Import backup'),
            subtitle: const Text('Replaces all data on this device'),
            onTap: () => importBackupFlow(context, ref),
          ),
          const _SectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline, color: AppColors.textSecondary),
            title: Text('Version'),
            trailing: Text(
              '0.15.0',
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

String _leadLabel(int days) => switch (days) {
  0 => 'On the due date',
  1 => '1 day before',
  3 => '3 days before',
  7 => '1 week before',
  _ => '$days days before',
};

Future<void> _setRemindersEnabled(WidgetRef ref, bool value) async {
  await ref.read(notificationPrefsProvider.notifier).setEnabled(value);
  if (value) {
    await ref.read(notificationServiceProvider).requestPermission();
  }
  await ref.read(reminderSchedulerProvider).rescheduleAll();
}

Future<void> _pickLeadDays(BuildContext context, WidgetRef ref) async {
  final current = ref.read(notificationPrefsProvider).leadDays;
  final choice = await showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in const [0, 1, 3, 7])
            ListTile(
              title: Text(_leadLabel(option)),
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
    await ref.read(notificationPrefsProvider.notifier).setLeadDays(choice);
    await ref.read(reminderSchedulerProvider).rescheduleAll();
  }
}

Future<void> _sendTestNotification(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final granted = await ref
      .read(notificationServiceProvider)
      .requestPermission();
  if (!granted) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Enable notifications for ClientVault in system settings.',
        ),
      ),
    );
    return;
  }
  await ref
      .read(notificationServiceProvider)
      .showNow(
        id: 999999,
        title: 'ClientVault',
        body: "Reminders are on — you'll hear from us before due dates.",
      );
  messenger.showSnackBar(
    const SnackBar(content: Text('Test notification sent.')),
  );
}

void _changePassword(BuildContext context, VaultStatus status) {
  switch (status) {
    case VaultStatus.locked:
    case VaultStatus.unlocked:
      showChangeMasterPasswordSheet(context);
    case VaultStatus.uninitialized:
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Set up your vault first.')));
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
  const _SoonTile({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
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
