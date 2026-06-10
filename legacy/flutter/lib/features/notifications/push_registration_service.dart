import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A device's registration with the push backend (APNs token relayed through
/// SNS/Pinpoint once the AWS backend exists).
class PushRegistration {
  const PushRegistration({required this.token, required this.platform});

  final String token;
  final String platform;
}

/// Contract for remote push. Local due-date reminders already work without
/// this; remote push (GitHub repo activity, cross-device alerts) needs an
/// APNs key and a relay service, so the real implementation lands with the
/// cloud backend. Registering swaps `pushRegistrationServiceProvider`.
abstract class PushRegistrationService {
  /// Whether the backend half exists yet.
  bool get isAvailable;

  /// Registers this device and returns the registration, or null when the
  /// backend is not available.
  Future<PushRegistration?> register();

  Future<void> unregister();
}

/// Pre-backend implementation: nothing to register with yet.
class LocalPushRegistrationService implements PushRegistrationService {
  const LocalPushRegistrationService();

  @override
  bool get isAvailable => false;

  @override
  Future<PushRegistration?> register() async => null;

  @override
  Future<void> unregister() async {}
}

final pushRegistrationServiceProvider = Provider<PushRegistrationService>(
  (ref) => const LocalPushRegistrationService(),
);
