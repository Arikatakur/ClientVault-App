import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/id.dart';
import '../../../data/local/app_database.dart';
import '../../../data/providers/database_provider.dart';
import '../payment_status.dart';

const List<String> _currencies = ['USD', 'ILS', 'EUR', 'GBP', 'AUD', 'CAD'];

/// Shows the add/edit payment form for a project. Writes to the database and
/// pops itself; pass [existing] to edit.
Future<void> showPaymentSheet(
  BuildContext context, {
  required String projectId,
  required String defaultCurrency,
  Payment? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PaymentForm(
      projectId: projectId,
      defaultCurrency: defaultCurrency,
      existing: existing,
    ),
  );
}

class _PaymentForm extends ConsumerStatefulWidget {
  const _PaymentForm({
    required this.projectId,
    required this.defaultCurrency,
    this.existing,
  });

  final String projectId;
  final String defaultCurrency;
  final Payment? existing;

  @override
  ConsumerState<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends ConsumerState<_PaymentForm> {
  late final TextEditingController _amount;
  late final TextEditingController _paidAmount;
  late final TextEditingController _notes;

  late PaymentStatus _status;
  late String _currency;
  DateTime? _issued;
  DateTime? _due;
  DateTime? _paid;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final payment = widget.existing;
    _amount = TextEditingController(text: _amountToText(payment?.amount));
    _paidAmount = TextEditingController(
      text: _amountToText(payment?.paidAmount),
    );
    _notes = TextEditingController(text: payment?.notes ?? '');
    _status = payment != null
        ? PaymentStatus.fromValue(payment.status)
        : PaymentStatus.draft;
    _currency = payment?.currency ?? widget.defaultCurrency;
    _issued = payment?.issuedDate;
    _due = payment?.dueDate;
    _paid = payment?.paidDate;
  }

  @override
  void dispose() {
    _amount.dispose();
    _paidAmount.dispose();
    _notes.dispose();
    super.dispose();
  }

  static String _amountToText(double? amount) {
    if (amount == null) return '';
    if (amount == amount.roundToDouble()) return amount.toInt().toString();
    return amount.toString();
  }

  String? _trimToNull(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<DateTime?> _pickDate(DateTime? initial) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 5),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }
    final paidAmount = double.tryParse(_paidAmount.text.trim()) ?? 0.0;
    setState(() {
      _busy = true;
      _error = null;
    });
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    final paidDate = _status == PaymentStatus.paid ? _paid : null;
    final existing = widget.existing;
    try {
      if (existing == null) {
        await db.insertPayment(
          PaymentsCompanion.insert(
            id: newId(),
            projectId: widget.projectId,
            amount: amount,
            paidAmount: Value(paidAmount),
            currency: Value(_currency),
            status: Value(_status.value),
            issuedDate: Value(_issued),
            dueDate: Value(_due),
            paidDate: Value(paidDate),
            notes: Value(_trimToNull(_notes)),
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else {
        await db.updatePayment(
          existing.id,
          PaymentsCompanion(
            amount: Value(amount),
            paidAmount: Value(paidAmount),
            currency: Value(_currency),
            status: Value(_status.value),
            issuedDate: Value(_issued),
            dueDate: Value(_due),
            paidDate: Value(paidDate),
            notes: Value(_trimToNull(_notes)),
            updatedAt: Value(now),
          ),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not save the payment.';
        });
      }
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    await ref.read(databaseProvider).deletePayment(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEditing = widget.existing != null;

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    isEditing ? 'Edit payment' : 'New payment',
                    style: textTheme.titleLarge,
                  ),
                ),
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: AppColors.danger,
                    tooltip: 'Delete payment',
                    onPressed: _delete,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _amount,
                    autofocus: !isEditing,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '\$ ',
                    ),
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
            TextField(
              controller: _paidAmount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount paid so far',
                helperText: 'Leave at 0 if unpaid; partial amounts are fine.',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Status', style: textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final status in PaymentStatus.values)
                  ChoiceChip(
                    label: Text(status.label),
                    selected: _status == status,
                    onSelected: (_) => setState(() {
                      _status = status;
                      if (status == PaymentStatus.paid) {
                        _paid ??= DateTime.now();
                        _paidAmount.text = _amount.text;
                      }
                    }),
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
            const SizedBox(height: AppSpacing.sm),
            _DateRow(
              label: 'Issued',
              value: _issued,
              onPick: () async {
                final picked = await _pickDate(_issued);
                if (picked != null) setState(() => _issued = picked);
              },
              onClear: () => setState(() => _issued = null),
            ),
            _DateRow(
              label: 'Due',
              value: _due,
              onPick: () async {
                final picked = await _pickDate(_due);
                if (picked != null) setState(() => _due = picked);
              },
              onClear: () => setState(() => _due = null),
            ),
            if (_status == PaymentStatus.paid)
              _DateRow(
                label: 'Paid',
                value: _paid,
                onPick: () async {
                  final picked = await _pickDate(_paid);
                  if (picked != null) setState(() => _paid = picked);
                },
                onClear: () => setState(() => _paid = null),
              ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notes,
              maxLines: 2,
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
                  : Text(isEditing ? 'Save changes' : 'Add payment'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            value == null ? '$label: not set' : '$label ${formatDate(value!)}',
            style: textTheme.bodyMedium,
          ),
        ),
        if (value != null)
          TextButton(onPressed: onClear, child: const Text('Clear')),
        TextButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.event_outlined, size: 18),
          label: Text(value == null ? 'Set' : 'Change'),
        ),
      ],
    );
  }
}
