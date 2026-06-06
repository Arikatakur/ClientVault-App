import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/local/app_database.dart';

/// Stored payment status. "Overdue" is derived from [isPaymentOverdue] rather
/// than stored, so it never goes stale.
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

/// A payment is overdue when it is unpaid and past its due date.
bool isPaymentOverdue(Payment payment) {
  if (payment.status == PaymentStatus.paid.value) return false;
  final due = payment.dueDate;
  return due != null && due.isBefore(DateTime.now());
}
