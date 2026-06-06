import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../vault_controller.dart';

/// Bottom sheet to change the vault's master password (re-wraps the data key).
Future<void> showChangeMasterPasswordSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _ChangeMasterPasswordSheet(),
  );
}

class _ChangeMasterPasswordSheet extends ConsumerStatefulWidget {
  const _ChangeMasterPasswordSheet();

  @override
  ConsumerState<_ChangeMasterPasswordSheet> createState() =>
      _ChangeMasterPasswordSheetState();
}

class _ChangeMasterPasswordSheetState
    extends ConsumerState<_ChangeMasterPasswordSheet> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final next = _next.text;
    if (next.length < 8) {
      setState(() => _error = 'New password must be at least 8 characters.');
      return;
    }
    if (next != _confirm.text) {
      setState(() => _error = 'New passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await ref
        .read(vaultControllerProvider.notifier)
        .changeMasterPassword(_current.text, next);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Master password changed.')),
      );
    } else {
      setState(() {
        _busy = false;
        _error = 'Current password is incorrect.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Change master password', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _current,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Current password',
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
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _next,
            obscureText: _obscure,
            decoration: const InputDecoration(labelText: 'New password'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _confirm,
            obscureText: _obscure,
            decoration: const InputDecoration(
              labelText: 'Confirm new password',
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Change password'),
          ),
        ],
      ),
    );
  }
}
