import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/local/app_database.dart';

/// Stored invoicing status. The *effective* status shown to the user also
/// accounts for partial payments and overdue state — see [paymentDisplay].
enum PaymentStatus {
  draft('draft', 'Draft', AppColors.textTertiary),
  sent('sent', 'Sent', AppColors.warning),
  paid('paid', 'Paid', AppColors.success);

  const PaymentStatus(this.value, this.label, this.color);

  final String value;
  final String label;
  final Color color;

  static PaymentStatus fromValue(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PaymentStatus.draft,
    );
  }
}

/// A payment is overdue when money is still owed and it is past its due date.
bool isPaymentOverdue(Payment payment) {
  if (payment.paidAmount >= payment.amount) return false;
  final due = payment.dueDate;
  return due != null && due.isBefore(DateTime.now());
}

/// How a payment should be labelled and coloured, accounting for partial
/// payments and overdue state.
({String label, Color color}) paymentDisplay(Payment payment) {
  if (payment.amount > 0 && payment.paidAmount >= payment.amount) {
    return (label: 'Paid', color: AppColors.success);
  }
  if (payment.paidAmount > 0) {
    return (label: 'Partial', color: AppColors.accent);
  }
  if (isPaymentOverdue(payment)) {
    return (label: 'Overdue', color: AppColors.danger);
  }
  final status = PaymentStatus.fromValue(payment.status);
  return (label: status.label, color: status.color);
}
