// Verifies the pure due-date reminder planning logic.

import 'package:clientvault/data/local/app_database.dart';
import 'package:clientvault/features/notifications/reminder_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

Payment _payment({
  required String id,
  required DateTime? dueDate,
  double amount = 100.0,
  double paidAmount = 0.0,
  String projectId = 'pr1',
}) {
  final now = DateTime(2026, 1, 1);
  return Payment(
    id: id,
    projectId: projectId,
    amount: amount,
    paidAmount: paidAmount,
    currency: 'USD',
    status: 'sent',
    dueDate: dueDate,
    createdAt: now,
    updatedAt: now,
  );
}

Project _project({
  required String id,
  DateTime? dueDate,
  String status = 'active',
  String name = 'Acme site',
}) {
  final now = DateTime(2026, 1, 1);
  return Project(
    id: id,
    clientId: 'c1',
    name: name,
    status: status,
    currency: 'USD',
    dueDate: dueDate,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  final now = DateTime(2026, 6, 1, 12); // noon, 1 Jun 2026

  test('schedules a reminder leadDays before a future payment due date', () {
    final plans = buildReminderPlans(
      payments: [_payment(id: 'p1', dueDate: DateTime(2026, 6, 20))],
      projects: const [],
      leadDays: 3,
      now: now,
    );
    expect(plans, hasLength(1));
    expect(plans.single.when, DateTime(2026, 6, 17, reminderHour));
    expect(plans.single.payload, '/projects/pr1');
  });

  test('skips fully-paid payments', () {
    final plans = buildReminderPlans(
      payments: [
        _payment(
          id: 'p1',
          dueDate: DateTime(2026, 6, 20),
          amount: 100,
          paidAmount: 100,
        ),
      ],
      projects: const [],
      leadDays: 1,
      now: now,
    );
    expect(plans, isEmpty);
  });

  test('skips payments and projects with past due dates', () {
    final plans = buildReminderPlans(
      payments: [_payment(id: 'p1', dueDate: DateTime(2020, 1, 1))],
      projects: [_project(id: 'pr1', dueDate: DateTime(2020, 1, 1))],
      leadDays: 1,
      now: now,
    );
    expect(plans, isEmpty);
  });

  test('skips payments without a due date', () {
    final plans = buildReminderPlans(
      payments: [_payment(id: 'p1', dueDate: null)],
      projects: const [],
      leadDays: 1,
      now: now,
    );
    expect(plans, isEmpty);
  });

  test('falls back to the due day when the lead point already passed', () {
    // Due in 2 days, lead 7 days: the lead point is in the past, but the due
    // day (09:00) is still ahead, so it still schedules for the due day.
    final plans = buildReminderPlans(
      payments: [_payment(id: 'p1', dueDate: DateTime(2026, 6, 3))],
      projects: const [],
      leadDays: 7,
      now: now,
    );
    expect(plans, hasLength(1));
    expect(plans.single.when, DateTime(2026, 6, 3, reminderHour));
  });

  test('skips done projects but keeps active ones', () {
    final plans = buildReminderPlans(
      payments: const [],
      projects: [
        _project(id: 'pr1', dueDate: DateTime(2026, 6, 20), status: 'done'),
        _project(id: 'pr2', dueDate: DateTime(2026, 6, 20)),
      ],
      leadDays: 1,
      now: now,
    );
    expect(plans, hasLength(1));
    expect(plans.single.title, 'Project deadline');
  });

  test('payment reminder body names its project', () {
    final plans = buildReminderPlans(
      payments: [
        _payment(id: 'p1', dueDate: DateTime(2026, 6, 20), projectId: 'pr1'),
      ],
      projects: [_project(id: 'pr1', name: 'Acme site', dueDate: null)],
      leadDays: 1,
      now: now,
    );
    expect(plans.first.body, contains('Acme site'));
  });

  test('reminder ids are namespaced and detected as reminders', () {
    expect(isReminderId(stableNotificationId(paymentIdBase, 'p1')), isTrue);
    expect(isReminderId(stableNotificationId(projectIdBase, 'pr1')), isTrue);
    expect(isReminderId(stableNotificationId(githubIdBase, 'x')), isFalse);
    expect(isReminderId(999999), isFalse); // the test-notification id
  });
}
