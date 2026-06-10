import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../vault/vault_controller.dart';
import 'backup_codec.dart';
import 'backup_service.dart';

/// Settings → "Export encrypted backup". Asks for a passphrase (twice),
/// builds the encrypted file, and hands it to the system save dialog.
Future<void> exportBackupFlow(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final passphrase = await _promptPassphrase(
    context,
    title: 'Protect your backup',
    explanation:
        'The backup is encrypted with this passphrase. Without it the file '
        'cannot be opened — store it somewhere safe.',
    confirm: true,
  );
  if (passphrase == null || !context.mounted) return;

  final bytes = await _withProgress(
    context,
    ref.read(backupServiceProvider).createBackup(passphrase),
  );
  if (bytes == null) return;

  final stamp = DateTime.now().toIso8601String().substring(0, 10);
  final savedPath = await FilePicker.platform.saveFile(
    dialogTitle: 'Save ClientVault backup',
    fileName: 'clientvault-$stamp.cvbackup',
    bytes: bytes,
  );
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        savedPath == null ? 'Export cancelled.' : 'Encrypted backup saved.',
      ),
    ),
  );
}

/// Settings → "Import backup". Warns that everything is replaced, picks the
/// file, asks for its passphrase, restores, and relocks the vault.
Future<void> importBackupFlow(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Replace everything on this device?'),
      content: const Text(
        'Importing a backup replaces all clients, projects, payments, and '
        'the vault. The vault will unlock with the master password from the '
        'backup. Attachment files are not part of backups and will be '
        'cleared.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Replace'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final picked = await FilePicker.platform.pickFiles(withData: true);
  final bytes = picked?.files.firstOrNull?.bytes;
  if (bytes == null || !context.mounted) return;

  final passphrase = await _promptPassphrase(
    context,
    title: 'Backup passphrase',
    explanation: 'Enter the passphrase this backup was exported with.',
    confirm: false,
  );
  if (passphrase == null || !context.mounted) return;

  try {
    final summary = await _withProgress(
      context,
      ref.read(backupServiceProvider).restoreBackup(bytes, passphrase),
      rethrowBackupErrors: true,
    );
    if (summary == null) return;
    await ref.read(vaultControllerProvider.notifier).reload();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Restored ${summary.clients} clients, ${summary.projects} '
          'projects, ${summary.payments} payments, and '
          '${summary.vaultItems} vault items.',
        ),
      ),
    );
  } on BackupException catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(error.message)));
  }
}

/// Runs [future] behind a modal spinner. Returns null if it failed with a
/// [BackupException] and [rethrowBackupErrors] is false.
Future<T?> _withProgress<T>(
  BuildContext context,
  Future<T> future, {
  bool rethrowBackupErrors = false,
}) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    return await future;
  } on BackupException catch (error) {
    if (rethrowBackupErrors) rethrow;
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
    return null;
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

Future<String?> _promptPassphrase(
  BuildContext context, {
  required String title,
  required String explanation,
  required bool confirm,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PassphraseSheet(
      title: title,
      explanation: explanation,
      confirm: confirm,
    ),
  );
}

class _PassphraseSheet extends StatefulWidget {
  const _PassphraseSheet({
    required this.title,
    required this.explanation,
    required this.confirm,
  });

  final String title;
  final String explanation;
  final bool confirm;

  @override
  State<_PassphraseSheet> createState() => _PassphraseSheetState();
}

class _PassphraseSheetState extends State<_PassphraseSheet> {
  final _passphrase = TextEditingController();
  final _repeat = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _passphrase.dispose();
    _repeat.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _passphrase.text;
    if (widget.confirm && value.length < 8) {
      setState(() => _error = 'Use at least 8 characters.');
      return;
    }
    if (widget.confirm && value != _repeat.text) {
      setState(() => _error = 'Passphrases do not match.');
      return;
    }
    if (value.isEmpty) {
      setState(() => _error = 'Enter the passphrase.');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(widget.explanation, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _passphrase,
            obscureText: _obscure,
            autofocus: true,
            onSubmitted: widget.confirm ? null : (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Passphrase',
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
          if (widget.confirm) ...[
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _repeat,
              obscureText: _obscure,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(labelText: 'Repeat passphrase'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _submit,
            child: Text(widget.confirm ? 'Encrypt backup' : 'Continue'),
          ),
        ],
      ),
    );
  }
}
