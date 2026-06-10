import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper around `flutter_local_notifications`. Owns plugin setup, the
/// timezone database, permission requests, and the two notification channels
/// the app uses. All work is local/on-device — there is no push server.
///
/// Methods are safe to call on web or in tests: the underlying plugin is a
/// no-op when it can't detect a supported platform.
class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  /// Android channel for due-date reminders (payments and projects).
  static const _remindersChannelId = 'reminders';
  static const _remindersChannelName = 'Reminders';

  /// Initializes the timezone database and the plugin. Idempotent. Permission
  /// prompts are deferred to [requestPermission] so we control the timing.
  Future<void> init({
    void Function(String? payload)? onSelectNotification,
  }) async {
    if (_initialized) return;
    _initialized = true;

    try {
      tz_data.initializeTimeZones();
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Web/unsupported: leave the default (UTC). Scheduling is a no-op there.
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    try {
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (response) =>
            onSelectNotification?.call(response.payload),
      );
    } catch (_) {
      // Platform without the plugin (tests/web): notifications are a no-op.
    }
  }

  /// Asks the OS for permission to post notifications. On iOS this shows the
  /// system prompt the first time; later calls return the current grant state.
  /// Returns true when granted (best-effort; null/failure = false).
  Future<bool> requestPermission() async {
    try {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }
    } catch (_) {
      // No plugin on this platform.
    }
    return false;
  }

  NotificationDetails get _reminderDetails => const NotificationDetails(
    android: AndroidNotificationDetails(
      _remindersChannelId,
      _remindersChannelName,
      channelDescription: 'Payment and project due-date reminders',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Shows a notification immediately (used for the settings "test" action).
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _reminderDetails,
        payload: payload,
      );
    } catch (_) {
      /* best-effort */
    }
  }

  /// Schedules a reminder at [when] (local time). Past times are ignored by the
  /// caller. Uses inexact scheduling on Android so no exact-alarm permission is
  /// needed; iOS uses a calendar trigger and fires while the app is closed.
  Future<void> scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: _reminderDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    } catch (_) {
      /* best-effort */
    }
  }

  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (_) {
      /* best-effort */
    }
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {
      /* best-effort */
    }
  }

  /// Notifications scheduled but not yet delivered (empty if unavailable).
  Future<List<PendingNotificationRequest>> pending() async {
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (_) {
      return const [];
    }
  }
}

/// App-wide notification service.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
