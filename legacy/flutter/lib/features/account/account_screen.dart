import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/format.dart';
import 'account_controller.dart';
import 'account_models.dart';

/// `/account` — the sign-in / create-account flow when signed out, and the
/// profile (sign out, delete account) when signed in.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: switch (account.status) {
        AccountStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        AccountStatus.signedOut => const _AuthView(),
        AccountStatus.signedIn => _ProfileView(user: account.user!),
      },
    );
  }
}

// --- Signed out: sign in / create account ------------------------------------

class _AuthView extends ConsumerStatefulWidget {
  const _AuthView();

  @override
  ConsumerState<_AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends ConsumerState<_AuthView> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _creating = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final controller = ref.read(accountControllerProvider.notifier);
    try {
      if (_creating) {
        await controller.signUp(
          email: _email.text,
          password: _password.text,
          displayName: _name.text,
        );
      } else {
        await controller.signIn(email: _email.text, password: _password.text);
      }
      HapticFeedback.mediumImpact();
    } on AuthException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _federated(Future<void> Function() action) async {
    try {
      await action();
      HapticFeedback.mediumImpact();
    } on AuthException catch (error) {
      _showMessage(error.message);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final controller = ref.read(accountControllerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          _creating ? 'Create your account' : 'Welcome back',
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'One identity for cloud sync, multi-device, and your subscription.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.cloud_off_outlined, color: AppColors.warning),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Accounts are stored on this device for now — they move '
                    'to ClientVault Cloud automatically when sync launches.',
                    style: textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_creating) ...[
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name (optional)'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _password,
          obscureText: _obscure,
          onSubmitted: (_) => _busy ? null : _submit(),
          decoration: InputDecoration(
            labelText: 'Password',
            helperText: _creating ? 'At least 8 characters' : null,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_creating ? 'Create account' : 'Sign in'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () => setState(() => _creating = !_creating),
          child: Text(
            _creating
                ? 'Already have an account? Sign in'
                : 'New here? Create an account',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('or continue with', style: textTheme.bodySmall),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: () => _federated(controller.signInWithApple),
          icon: const Icon(Icons.apple),
          label: const Text('Continue with Apple'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => _federated(controller.signInWithGoogle),
          icon: const Icon(Icons.g_mobiledata),
          label: const Text('Continue with Google'),
        ),
      ],
    );
  }
}

// --- Signed in: profile -------------------------------------------------------

class _ProfileView extends ConsumerWidget {
  const _ProfileView({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final initial =
        (user.displayName?.isNotEmpty == true ? user.displayName! : user.email)
            .substring(0, 1)
            .toUpperCase();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(
          child: CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.accentSoft,
            child: Text(
              initial,
              style: textTheme.headlineMedium?.copyWith(
                color: AppColors.accent,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(
            user.displayName ?? user.email,
            style: textTheme.titleLarge,
          ),
        ),
        if (user.displayName != null)
          Center(child: Text(user.email, style: textTheme.bodyMedium)),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Chip(
            label: Text(user.provider.label),
            labelStyle: textTheme.bodySmall,
            backgroundColor: AppColors.surfaceElevated,
            side: const BorderSide(color: AppColors.outline),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Text(
            'Member since ${formatDate(user.createdAt)}',
            style: textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton.icon(
          onPressed: () =>
              ref.read(accountControllerProvider.notifier).signOut(),
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Sign out'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => _confirmDelete(context, ref),
          icon: const Icon(Icons.delete_outline, size: 18),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
          label: const Text('Delete account'),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This removes the account from this device. Your clients, '
          'projects, payments, and vault stay untouched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(accountControllerProvider.notifier).deleteAccount();
    }
  }
}
