import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../vault_controller.dart';

/// First-run screen: choose the master password that encrypts the vault.
class VaultSetupView extends ConsumerStatefulWidget {
  const VaultSetupView({super.key});

  @override
  ConsumerState<VaultSetupView> createState() => _VaultSetupViewState();
}

class _VaultSetupViewState extends ConsumerState<VaultSetupView> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final password = _password.text;
    if (password.length < 8) {
      setState(() => _error = 'Use at least 8 characters.');
      return;
    }
    if (password != _confirm.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(vaultControllerProvider.notifier)
          .setupMasterPassword(password);
      // On success the status flips to unlocked and VaultScreen rebuilds.
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not create the vault. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strength = _PasswordStrength.of(_password.text);

    return Scaffold(
      appBar: AppBar(title: const Text('Vault')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Container(
              height: 72,
              width: 72,
              decoration: const BoxDecoration(
                color: AppColors.accentSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 34,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Create your vault',
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Set a master password. It encrypts everything in your vault, is '
            'never stored, and cannot be recovered — if you forget it, the '
            'vault cannot be opened.',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _password,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Master password',
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
          const SizedBox(height: AppSpacing.sm),
          if (_password.text.isNotEmpty) _StrengthBar(strength: strength),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _confirm,
            obscureText: _obscure,
            decoration: const InputDecoration(labelText: 'Confirm password'),
            onSubmitted: (_) => _create(),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _busy ? null : _create,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create vault'),
          ),
        ],
      ),
    );
  }
}

class _PasswordStrength {
  const _PasswordStrength(this.score, this.label, this.color);

  final int score; // filled segments, 1..3
  final String label;
  final Color color;

  static _PasswordStrength of(String password) {
    var points = 0;
    if (password.length >= 8) points++;
    if (password.length >= 12) points++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      points++;
    }
    if (RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      points++;
    }
    if (points <= 1) {
      return const _PasswordStrength(1, 'Weak', AppColors.danger);
    }
    if (points <= 3) {
      return const _PasswordStrength(2, 'Fair', AppColors.warning);
    }
    return const _PasswordStrength(3, 'Strong', AppColors.success);
  }
}

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.strength});

  final _PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i < strength.score ? strength.color : AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i < 2) const SizedBox(width: 6),
        ],
        const SizedBox(width: AppSpacing.sm),
        Text(
          strength.label,
          style: TextStyle(
            color: strength.color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
