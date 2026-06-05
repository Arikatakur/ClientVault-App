import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/local/app_database.dart';
import '../vault_controller.dart';
import '../vault_item_type.dart';
import '../vault_payload.dart';

/// Shows the add/edit form for a vault item. For edits, pass the already
/// [item] and its decrypted [payload]; the form re-encrypts on save.
Future<void> showVaultItemSheet(
  BuildContext context, {
  VaultItem? item,
  VaultPayload? payload,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _VaultItemForm(item: item, payload: payload),
  );
}

class _VaultItemForm extends ConsumerStatefulWidget {
  const _VaultItemForm({this.item, this.payload});

  final VaultItem? item;
  final VaultPayload? payload;

  @override
  ConsumerState<_VaultItemForm> createState() => _VaultItemFormState();
}

class _VaultItemFormState extends ConsumerState<_VaultItemForm> {
  late final TextEditingController _title;
  late final TextEditingController _username;
  late final TextEditingController _secret;
  late final TextEditingController _url;
  late final TextEditingController _notes;

  late VaultItemType _type;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    final payload = widget.payload;
    _type = item != null
        ? VaultItemType.fromValue(item.type)
        : VaultItemType.password;
    _title = TextEditingController(text: item?.title ?? '');
    _username = TextEditingController(text: payload?.username ?? '');
    _secret = TextEditingController(text: payload?.secret ?? '');
    _url = TextEditingController(text: payload?.url ?? '');
    _notes = TextEditingController(text: payload?.notes ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _username.dispose();
    _secret.dispose();
    _url.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _trimToNull(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Title is required.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final payload = VaultPayload(
      username: _trimToNull(_username),
      secret: _trimToNull(_secret),
      url: _trimToNull(_url),
      notes: _trimToNull(_notes),
    );
    final notifier = ref.read(vaultControllerProvider.notifier);
    try {
      final item = widget.item;
      if (item == null) {
        await notifier.addItem(type: _type, title: title, payload: payload);
      } else {
        await notifier.updateItem(
          id: item.id,
          type: _type,
          title: title,
          payload: payload,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not save the item.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEditing = widget.item != null;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? 'Edit item' : 'New item',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final type in VaultItemType.values)
                  ChoiceChip(
                    avatar: Icon(
                      type.icon,
                      size: 18,
                      color: _type == type
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                    label: Text(type.label),
                    selected: _type == type,
                    onSelected: (_) => setState(() => _type = type),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _title,
              autofocus: !isEditing,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Acme production server',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _username,
              decoration: const InputDecoration(
                labelText: 'Username / email (optional)',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _secret,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: '${_type.secretLabel} (optional)',
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
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'URL (optional)'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notes,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Save changes' : 'Save item'),
            ),
          ],
        ),
      ),
    );
  }
}
