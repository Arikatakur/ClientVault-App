import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_service.dart';
import '../../data/providers/database_provider.dart';
import 'notification_prefs.dart';
import 'reminder_scheduler.dart';

/// Mounted once near the app root. Requests notification permission on first
/// launch, schedules due-date reminders, and re-syncs them whenever the
/// payments/projects data changes or the app returns to the foreground.
class NotificationsBootstrap extends ConsumerStatefulWidget {
  const NotificationsBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationsBootstrap> createState() =>
      _NotificationsBootstrapState();
}

class _NotificationsBootstrapState extends ConsumerState<NotificationsBootstrap>
    with WidgetsBindingObserver {
  Timer? _debounce;
  bool _askedPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (!_askedPermission && ref.read(notificationPrefsProvider).enabled) {
      _askedPermission = true;
      await ref.read(notificationServiceProvider).requestPermission();
    }
    await ref.read(reminderSchedulerProvider).rescheduleAll();
  }

  /// Coalesces bursts of data changes into a single reschedule.
  void _scheduleReschedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      ref.read(reminderSchedulerProvider).rescheduleAll();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _scheduleReschedule();
  }

  @override
  Widget build(BuildContext context) {
    // Re-sync reminders (debounced) whenever the underlying data changes.
    ref.listen(paymentsStreamProvider, (_, _) => _scheduleReschedule());
    ref.listen(projectsStreamProvider, (_, _) => _scheduleReschedule());
    return widget.child;
  }
}
