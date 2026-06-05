import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/id.dart';
import '../../../data/local/app_database.dart';
import '../../../data/providers/database_provider.dart';

/// Shows the create/edit client form as a bottom sheet. Pass [existing] to
/// edit an existing client; omit it to create a new one.
Future<void> showClientFormSheet(
  BuildContext context,
  WidgetRef ref, {
  Client? existing,
}) async {
  final result = await showModalBottomSheet<_ClientFormResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _ClientForm(existing: existing),
  );
  if (result == null) return;

  final db = ref.read(databaseProvider);
  final now = DateTime.now();
  if (existing == null) {
    await db.insertClient(
      ClientsCompanion.insert(
        id: newId(),
        name: result.name,
        company: Value(result.company),
        email: Value(result.email),
        phone: Value(result.phone),
        notes: Value(result.notes),
        createdAt: now,
        updatedAt: now,
      ),
    );
  } else {
    await db.updateClient(
      existing.id,
      ClientsCompanion(
        name: Value(result.name),
        company: Value(result.company),
        email: Value(result.email),
        phone: Value(result.phone),
        notes: Value(result.notes),
        updatedAt: Value(now),
      ),
    );
  }
}

class _ClientFormResult {
  const _ClientFormResult({
    required this.name,
    this.company,
    this.email,
    this.phone,
    this.notes,
  });

  final String name;
  final String? company;
  final String? email;
  final String? phone;
  final String? notes;
}

class _ClientForm extends StatefulWidget {
  const _ClientForm({this.existing});

  final Client? existing;

  @override
  State<_ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends State<_ClientForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _company;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final client = widget.existing;
    _name = TextEditingController(text: client?.name ?? '');
    _company = TextEditingController(text: client?.company ?? '');
    _email = TextEditingController(text: client?.email ?? '');
    _phone = TextEditingController(text: client?.phone ?? '');
    _notes = TextEditingController(text: client?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    _email.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _trimToNull(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _ClientFormResult(
        name: _name.text.trim(),
        company: _trimToNull(_company),
        email: _trimToNull(_email),
        phone: _trimToNull(_phone),
        notes: _trimToNull(_notes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? 'Edit client' : 'New client',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _name,
              autofocus: !isEditing,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Acme Studios',
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Name is required'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _company,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Company (optional)',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email (optional)'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone (optional)'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _submit,
              child: Text(isEditing ? 'Save changes' : 'Save client'),
            ),
          ],
        ),
      ),
    );
  }
}
