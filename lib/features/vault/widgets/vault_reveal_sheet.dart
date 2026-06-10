import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/local/app_database.dart';
import '../../../data/providers/database_provider.dart';
import '../vault_controller.dart';
import '../vault_item_type.dart';
import '../vault_payload.dart';
import 'vault_item_form_sheet.dart';

/// Decrypts and reveals one vault item. [parentContext] is the originating
/// screen's context, used to reopen the edit form after this sheet closes.
Future<void> showVaultRevealSheet(BuildContext context, VaultItem item) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _VaultRevealSheet(item: item, parentContext: context),
  );
}

class _VaultRevealSheet extends ConsumerStatefulWidget {
  const _VaultRevealSheet({required this.item, required this.parentContext});

  final VaultItem item;
  final BuildContext parentContext;

  @override
  ConsumerState<_VaultRevealSheet> createState() => _VaultRevealSheetState();
}

class _VaultRevealSheetState extends ConsumerState<_VaultRevealSheet> {
  VaultPayload? _payload;
  bool _loading = true;
  bool _failed = false;
  bool _secretVisible = false;

  @override
  void initState() {
    super.initState();
    _decrypt();
  }

  Future<void> _decrypt() async {
    try {
      final payload = await ref
          .read(vaultControllerProvider.notifier)
          .reveal(widget.item);
      if (mounted) {
        setState(() {
          _payload = payload;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  void _copy(String label, String value) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: value));
    // Clear the clipboard after 30s, but only if it still holds this value.
    Future.delayed(const Duration(seconds: 30), () async {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text == value) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copied — clears in 30s')));
  }

  Future<void> _edit() async {
    final payload = _payload;
    if (payload == null) return;
    Navigator.of(context).pop();
    await showVaultItemSheet(
      widget.parentContext,
      item: widget.item,
      payload: payload,
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('This permanently deletes ${widget.item.title}.'),
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
    if (confirmed != true) return;
    await ref.read(vaultControllerProvider.notifier).deleteItem(widget.item.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final type = VaultItemType.fromValue(widget.item.type);
    final payload = _payload;
    final clientId = widget.item.clientId;
    final projectId = widget.item.projectId;
    final linkedClient = clientId == null
        ? null
        : ref.watch(clientByIdProvider(clientId)).value;
    final linkedProject = projectId == null
        ? null
        : ref.watch(projectByIdProvider(projectId)).value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.accentSoft,
                child: Icon(type.icon, color: AppColors.accent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.item.title, style: textTheme.titleMedium),
                    Text(type.label, style: textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          if (linkedClient != null || linkedProject != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                if (linkedClient != null)
                  Chip(
                    avatar: const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    label: Text(linkedClient.name),
                    labelStyle: textTheme.bodySmall,
                    backgroundColor: AppColors.surfaceElevated,
                    side: const BorderSide(color: AppColors.outline),
                  ),
                if (linkedProject != null)
                  Chip(
                    avatar: const Icon(
                      Icons.folder_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    label: Text(linkedProject.name),
                    labelStyle: textTheme.bodySmall,
                    backgroundColor: AppColors.surfaceElevated,
                    side: const BorderSide(color: AppColors.outline),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_failed)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Could not decrypt this item.',
                style: textTheme.bodyMedium,
              ),
            )
          else if (payload != null) ...[
            if (payload.username != null)
              _FieldRow(
                label: 'Username',
                value: payload.username!,
                onCopy: () => _copy('Username', payload.username!),
              ),
            if (payload.secret != null)
              _FieldRow(
                label: type.secretLabel,
                value: _secretVisible ? payload.secret! : '••••••••••',
                onCopy: () => _copy(type.secretLabel, payload.secret!),
                trailing: IconButton(
                  icon: Icon(
                    _secretVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  tooltip: _secretVisible ? 'Hide' : 'Reveal',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _secretVisible = !_secretVisible);
                  },
                ),
              ),
            if (payload.url != null)
              _FieldRow(
                label: 'URL',
                value: payload.url!,
                onCopy: () => _copy('URL', payload.url!),
              ),
            if (payload.notes != null)
              _FieldRow(label: 'Notes', value: payload.notes!),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _failed ? null : _edit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.value,
    this.onCopy,
    this.trailing,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                // Cross-fades when the secret toggles between dots and text.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    value,
                    key: ValueKey(value),
                    style: textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy_outlined, size: 18),
              tooltip: 'Copy',
              color: AppColors.textSecondary,
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }
}
