// Verifies the derived "overdue" rule for payments.

import 'package:clientvault/data/local/app_database.dart';
import 'package:clientvault/features/payments/payment_status.dart';
import 'package:flutter_test/flutter_test.dart';

Payment _payment({required String status, DateTime? dueDate}) {
  final now = DateTime(2026, 1, 1);
  return Payment(
    id: 'p1',
    projectId: 'pr1',
    amount: 100.0,
    currency: 'USD',
    status: status,
    dueDate: dueDate,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('unpaid payment past its due date is overdue', () {
    expect(
      isPaymentOverdue(_payment(status: 'sent', dueDate: DateTime(2020, 1, 1))),
      isTrue,
    );
  });

  test('paid payment is never overdue', () {
    expect(
      isPaymentOverdue(_payment(status: 'paid', dueDate: DateTime(2020, 1, 1))),
      isFalse,
    );
  });

  test('unpaid payment with a future due date is not overdue', () {
    expect(
      isPaymentOverdue(_payment(status: 'sent', dueDate: DateTime(2999, 1, 1))),
      isFalse,
    );
  });

  test('payment without a due date is not overdue', () {
    expect(isPaymentOverdue(_payment(status: 'draft')), isFalse);
  });
}
