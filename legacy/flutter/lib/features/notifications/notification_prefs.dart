import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/secure_store.dart';
import '../../core/storage/secure_store_provider.dart';

/// User preferences for reminders. Persisted in [SecureStore] alongside the
/// other on-device preferences.
class NotificationPrefs {
  const NotificationPrefs({required this.enabled, required this.leadDays});

  /// Master switch for due-date reminders.
  final bool enabled;

  /// How many days before a due date to remind (0 = on the day).
  final int leadDays;

  static const defaults = NotificationPrefs(enabled: true, leadDays: 1);

  NotificationPrefs copyWith({bool? enabled, int? leadDays}) {
    return NotificationPrefs(
      enabled: enabled ?? this.enabled,
      leadDays: leadDays ?? this.leadDays,
    );
  }
}

final notificationPrefsProvider =
    NotifierProvider<NotificationPrefsController, NotificationPrefs>(
      NotificationPrefsController.new,
    );

class NotificationPrefsController extends Notifier<NotificationPrefs> {
  late SecureStore _secure;

  @override
  NotificationPrefs build() {
    _secure = ref.watch(secureStoreProvider);
    _load();
    return NotificationPrefs.defaults;
  }

  Future<void> _load() async {
    try {
      final enabled = await _secure.readNotifEnabled();
      final leadDays = await _secure.readNotifLeadDays();
      state = NotificationPrefs(enabled: enabled, leadDays: leadDays);
    } catch (_) {
      // Secure storage unavailable (e.g. web preview/tests): keep defaults.
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    await _secure.writeNotifEnabled(enabled);
  }

  Future<void> setLeadDays(int days) async {
    state = state.copyWith(leadDays: days);
    await _secure.writeNotifLeadDays(days);
  }
}
