import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../vault_controller.dart';

/// Shown when the vault is set up but locked: master password + biometrics.
class VaultLockView extends ConsumerStatefulWidget {
  const VaultLockView({super.key});

  @override
  ConsumerState<VaultLockView> createState() => _VaultLockViewState();
}

class _VaultLockViewState extends ConsumerState<VaultLockView> {
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  bool _biometricReady = false;
  String? _error;
  int _attempts = 0; // re-runs the error shake on every failure

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    final notifier = ref.read(vaultControllerProvider.notifier);
    final available = await notifier.isBiometricAvailable();
    final enabled = await notifier.isBiometricEnabled();
    if (mounted) {
      setState(() => _biometricReady = available && enabled);
    }
  }

  Future<void> _unlock() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await ref
        .read(vaultControllerProvider.notifier)
        .unlock(_password.text);
    if (ok) {
      HapticFeedback.mediumImpact();
    } else if (mounted) {
      HapticFeedback.heavyImpact();
      setState(() {
        _busy = false;
        _error = 'Incorrect master password.';
        _attempts++;
      });
    }
  }

  Future<void> _biometricUnlock() async {
    final ok = await ref
        .read(vaultControllerProvider.notifier)
        .unlockWithBiometrics();
    if (ok) {
      HapticFeedback.mediumImpact();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric unlock failed — use your master password.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Vault')),
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child:
                  Container(
                        height: 72,
                        width: 72,
                        decoration: const BoxDecoration(
                          color: AppColors.accentSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          size: 34,
                          color: AppColors.accent,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .scale(
                        begin: const Offset(0.85, 0.85),
                        end: const Offset(1, 1),
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                      ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Vault locked',
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Enter your master password to unlock.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _password,
              obscureText: _obscure,
              autofocus: true,
              onSubmitted: (_) => _unlock(),
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
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: const TextStyle(color: AppColors.danger))
                  .animate(key: ValueKey(_attempts))
                  .shake(hz: 4, offset: const Offset(3, 0), rotation: 0),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _busy ? null : _unlock,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Unlock'),
            ),
            if (_biometricReady) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _busy ? null : _biometricUnlock,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock with biometrics'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
