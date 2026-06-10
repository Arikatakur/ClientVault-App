import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'github_controller.dart';
import 'github_models.dart';

/// Connect/disconnect GitHub via a personal access token. Reached from
/// Settings; pushed over the tab shell.
class GitHubConnectScreen extends ConsumerStatefulWidget {
  const GitHubConnectScreen({super.key});

  @override
  ConsumerState<GitHubConnectScreen> createState() =>
      _GitHubConnectScreenState();
}

class _GitHubConnectScreenState extends ConsumerState<GitHubConnectScreen> {
  final _token = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() => _busy = true);
    await ref.read(githubControllerProvider.notifier).connect(_token.text);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _disconnect() async {
    await ref.read(githubControllerProvider.notifier).disconnect();
    _token.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(githubControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('GitHub')),
      body: switch (state.status) {
        GitHubStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        GitHubStatus.connected => _ConnectedView(
          user: state.user!,
          onDisconnect: _disconnect,
        ),
        _ => _ConnectForm(
          controller: _token,
          obscure: _obscure,
          busy: _busy,
          error: state.error,
          onToggleObscure: () => setState(() => _obscure = !_obscure),
          onConnect: _connect,
        ),
      },
    );
  }
}

class _ConnectedView extends StatelessWidget {
  const _ConnectedView({required this.user, required this.onDisconnect});

  final GitHubUser user;
  final Future<void> Function() onDisconnect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.md),
        Center(
          child: CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.accentSoft,
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? const Icon(Icons.person, color: AppColors.accent)
                : null,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          user.name ?? user.login,
          style: textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        Text(
          '@${user.login}',
          style: textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.success),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Connected. Link a repository to a project from the '
                    "project's detail screen.",
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: onDisconnect,
          icon: const Icon(Icons.logout, size: 18),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
          label: const Text('Disconnect GitHub'),
        ),
      ],
    );
  }
}

class _ConnectForm extends StatelessWidget {
  const _ConnectForm({
    required this.controller,
    required this.obscure,
    required this.busy,
    required this.error,
    required this.onToggleObscure,
    required this.onConnect,
  });

  final TextEditingController controller;
  final bool obscure;
  final bool busy;
  final String? error;
  final VoidCallback onToggleObscure;
  final Future<void> Function() onConnect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Container(
            height: 72,
            width: 72,
            decoration: const BoxDecoration(
              color: AppColors.accentSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.code, size: 34, color: AppColors.accent),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Connect GitHub',
          style: textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Paste a fine-grained personal access token to browse your '
          'repositories and link them to projects. The token is stored only '
          'on this device, in the keychain.',
          style: textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create a token', style: textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '1.  GitHub → Settings → Developer settings\n'
                  '2.  Personal access tokens → Fine-grained tokens\n'
                  '3.  Repository access: your repos\n'
                  '4.  Permissions: Contents = Read-only, Metadata = Read-only\n'
                  '5.  Generate, then paste below',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            labelText: 'Personal access token',
            hintText: 'github_pat_…',
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: onToggleObscure,
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(error!, style: const TextStyle(color: AppColors.danger)),
        ],
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: busy ? null : onConnect,
          child: busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Connect'),
        ),
      ],
    );
  }
}
