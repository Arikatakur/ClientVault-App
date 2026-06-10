import 'package:local_auth/local_auth.dart';

/// Wraps `local_auth` for unlocking the vault with Face ID / Touch ID (falling
/// back to the device passcode). All failures collapse to `false` so callers
/// can keep a simple boolean flow.
class BiometricAuth {
  BiometricAuth([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// Whether the device can perform biometric/credential authentication.
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Prompts the user; returns whether authentication succeeded.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
