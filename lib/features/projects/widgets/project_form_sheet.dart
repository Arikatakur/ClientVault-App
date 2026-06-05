import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/id.dart';
import '../../../data/local/app_database.dart';
import '../../../data/providers/database_provider.dart';
import '../project_status.dart';

const List<String> _currencies = ['USD', 'EUR', 'GBP', 'AUD', 'CAD'];

/// Shows the create/edit project form. Pass [existing] to edit. Pass
/// [lockedClientId] to pre-select and hide the client picker (e.g. when adding
/// a project from a client's detail screen).
Future<void> showProjectFormSheet(
  BuildContext context,
  WidgetRef ref, {
  Project? existing,
  String? lockedClientId,
}) async {
  final clients = ref.read(clientsStreamProvider).value ?? const <Client>[];
  if (clients.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add a client first to attach a project.'),
      ),
    );
    return;
  }

  final result = await showModalBottomSheet<_ProjectFormResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _ProjectForm(
      clients: clients,
      existing: existing,
      lockedClientId: lockedClientId,
    ),
  );
  if (result == null) return;

  final db = ref.read(databaseProvider);
  final now = DateTime.now();
  if (existing == null) {
    await db.insertProject(
      ProjectsCompanion.insert(
        id: newId(),
        clientId: result.clientId,
        name: result.name,
        description: Value(result.description),
        status: Value(result.status),
        budget: Value(result.budget),
        currency: Value(result.currency),
        dueDate: Value(result.dueDate),
        createdAt: now,
        updatedAt: now,
      ),
    );
  } else {
    await db.updateProject(
      existing.id,
      ProjectsCompanion(
        clientId: Value(result.clientId),
        name: Value(result.name),
        description: Value(result.description),
        status: Value(result.status),
        budget: Value(result.budget),
        currency: Value(result.currency),
        dueDate: Value(result.dueDate),
        updatedAt: Value(now),
      ),
    );
  }
}

class _ProjectFormResult {
  const _ProjectFormResult({
    required this.name,
    required this.clientId,
    required this.status,
    required this.currency,
    this.budget,
    this.dueDate,
    this.description,
  });

  final String name;
  final String clientId;
  final String status;
  final String currency;
  final double? budget;
  final DateTime? dueDate;
  final String? description;
}

class _ProjectForm extends StatefulWidget {
  const _ProjectForm({
    required this.clients,
    this.existing,
    this.lockedClientId,
  });

  final List<Client> clients;
  final Project? existing;
  final String? lockedClientId;

  @override
  State<_ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<_ProjectForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _budget;
  late final TextEditingController _description;

  late String _clientId;
  late ProjectStatus _status;
  late String _currency;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final project = widget.existing;
    _name = TextEditingController(text: project?.name ?? '');
    _budget = TextEditingController(text: _budgetToText(project?.budget));
    _description = TextEditingController(text: project?.description ?? '');
    _clientId =
        widget.lockedClientId ??
        project?.clientId ??
        widget.clients.first.id;
    _status = project != null
        ? ProjectStatus.fromValue(project.status)
        : ProjectStatus.lead;
    _currency = project?.currency ?? 'USD';
    _dueDate = project?.dueDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _budget.dispose();
    _description.dispose();
    super.dispose();
  }

  static String _budgetToText(double? budget) {
    if (budget == null) return '';
    if (budget == budget.roundToDouble()) return budget.toInt().toString();
    return budget.toString();
  }

  String? _trimToNull(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final budgetText = _budget.text.trim();
    Navigator.of(context).pop(
      _ProjectFormResult(
        name: _name.text.trim(),
        clientId: _clientId,
        status: _status.value,
        currency: _currency,
        budget: budgetText.isEmpty ? null : double.tryParse(budgetText),
        dueDate: _dueDate,
        description: _trimToNull(_description),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final textTheme = Theme.of(context).textTheme;
    final lockedName = widget.lockedClientId == null
        ? null
        : widget.clients
              .firstWhere((c) => c.id == widget.lockedClientId)
              .name;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Edit project' : 'New project',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _name,
                autofocus: !isEditing,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Project name',
                  hintText: 'e.g. Marketing site redesign',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Project name is required'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              if (lockedName != null)
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Client'),
                  child: Text(lockedName),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _clientId,
                  decoration: const InputDecoration(labelText: 'Client'),
                  items: [
                    for (final client in widget.clients)
                      DropdownMenuItem(
                        value: client.id,
                        child: Text(client.name),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _clientId = value);
                  },
                ),
              const SizedBox(height: AppSpacing.lg),
              Text('Status', style: textTheme.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final status in ProjectStatus.values)
                    ChoiceChip(
                      label: Text(status.label),
                      selected: _status == status,
                      onSelected: (_) => setState(() => _status = status),
                      selectedColor: status.color.withValues(alpha: 0.22),
                      labelStyle: TextStyle(
                        color: _status == status
                            ? status.color
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _budget,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Budget (optional)',
                        prefixText: '\$ ',
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return null;
                        return double.tryParse(text) == null
                            ? 'Enter a number'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: const InputDecoration(labelText: 'Currency'),
                      items: [
                        for (final code in _currencies)
                          DropdownMenuItem(value: code, child: Text(code)),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _currency = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dueDate == null
                          ? 'No due date'
                          : 'Due ${formatDate(_dueDate!)}',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  if (_dueDate != null)
                    TextButton(
                      onPressed: () => setState(() => _dueDate = null),
                      child: const Text('Clear'),
                    ),
                  TextButton.icon(
                    onPressed: _pickDueDate,
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: Text(_dueDate == null ? 'Set date' : 'Change'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _description,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _submit,
                child: Text(isEditing ? 'Save changes' : 'Create project'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
