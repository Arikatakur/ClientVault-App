import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/utils/format.dart';
import '../../data/local/app_database.dart';
import '../../data/providers/database_provider.dart';
import 'notification_prefs.dart';

/// The local time of day reminders fire (24h clock).
const int reminderHour = 9;

/// Notification-id namespaces. Each entity maps to a stable id in its range so
/// re-scheduling replaces (rather than duplicates) its reminder, and reminders
/// can be told apart from other notifications (e.g. GitHub updates).
const int paymentIdBase = 1000000;
const int projectIdBase = 2000000;
const int githubIdBase = 3000000;

/// A stable, collision-resistant id for an entity's reminder within [base].
int stableNotificationId(int base, String entityId) =>
    base + (entityId.hashCode & 0xFFFFF);

/// Whether [id] belongs to a due-date reminder (payment or project).
bool isReminderId(int id) => id >= paymentIdBase && id < githubIdBase;

/// A single reminder to schedule: when to fire and what to say.
class ReminderPlan {
  const ReminderPlan({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
    this.payload,
  });

  final int id;
  final DateTime when;
  final String title;
  final String body;
  final String? payload;
}

/// Pure planning: turns the current data into the set of reminders that should
/// be scheduled. Kept free of plugin/IO so it is fully unit-testable.
///
/// Rules: only unpaid payments and not-done projects with a future-facing due
/// date are included; fully-paid payments and past deadlines are skipped.
List<ReminderPlan> buildReminderPlans({
  required List<Payment> payments,
  required List<Project> projects,
  required int leadDays,
  required DateTime now,
}) {
  final plans = <ReminderPlan>[];
  final projectsById = {for (final p in projects) p.id: p};

  for (final payment in payments) {
    final due = payment.dueDate;
    if (due == null) continue;
    final remaining = payment.amount - payment.paidAmount;
    if (remaining <= 0) continue; // fully paid
    final when = _reminderTime(due, leadDays, now);
    if (when == null) continue;
    final name = projectsById[payment.projectId]?.name ?? 'a project';
    plans.add(
      ReminderPlan(
        id: stableNotificationId(paymentIdBase, payment.id),
        when: when,
        title: 'Payment due soon',
        body:
            '${formatMoney(remaining, payment.currency)} for $name '
            '— due ${formatDate(due)}',
        payload: '/projects/${payment.projectId}',
      ),
    );
  }

  for (final project in projects) {
    final due = project.dueDate;
    if (due == null) continue;
    if (project.status == 'done') continue;
    final when = _reminderTime(due, leadDays, now);
    if (when == null) continue;
    plans.add(
      ReminderPlan(
        id: stableNotificationId(projectIdBase, project.id),
        when: when,
        title: 'Project deadline',
        body: '${project.name} — due ${formatDate(due)}',
        payload: '/projects/${project.id}',
      ),
    );
  }

  return plans;
}

/// The local time to fire a reminder for [due] given [leadDays] of notice, or
/// null if both the lead point and the due day itself have already passed.
DateTime? _reminderTime(DateTime due, int leadDays, DateTime now) {
  final dueAtHour = DateTime(due.year, due.month, due.day, reminderHour);
  final lead = dueAtHour.subtract(Duration(days: leadDays));
  if (lead.isAfter(now)) return lead;
  if (dueAtHour.isAfter(now)) return dueAtHour;
  return null;
}

/// Reconciles scheduled OS notifications with the current data + preferences.
class ReminderScheduler {
  ReminderScheduler(this._ref);

  final Ref _ref;

  /// Cancels existing reminders and schedules a fresh set. Safe to call often
  /// (on launch and whenever payments/projects change).
  Future<void> rescheduleAll() async {
    final service = _ref.read(notificationServiceProvider);

    // Drop only our reminder notifications, leaving any others untouched.
    final pending = await service.pending();
    for (final req in pending) {
      if (isReminderId(req.id)) await service.cancel(req.id);
    }

    if (!_ref.read(notificationPrefsProvider).enabled) return;

    final List<Payment> payments;
    final List<Project> projects;
    try {
      final db = _ref.read(databaseProvider);
      payments = await db.getAllPayments();
      projects = await db.getAllProjects();
    } catch (_) {
      return; // no on-device database (e.g. web preview/tests)
    }

    final plans = buildReminderPlans(
      payments: payments,
      projects: projects,
      leadDays: _ref.read(notificationPrefsProvider).leadDays,
      now: DateTime.now(),
    );
    for (final plan in plans) {
      await service.scheduleAt(
        id: plan.id,
        when: plan.when,
        title: plan.title,
        body: plan.body,
        payload: plan.payload,
      );
    }
  }
}

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  ReminderScheduler.new,
);
