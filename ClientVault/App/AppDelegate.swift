import UIKit

/// Minimal UIApplicationDelegate for receiving APNs token callbacks.
/// `onDeviceToken` is wired to `PushRegistrar.didRegister(deviceToken:)` by
/// `ClientVaultApp` once the environment is ready.
@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate {
    var onDeviceToken: ((Data) -> Void)?

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        onDeviceToken?(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Silently handled; PushRegistrar.authorizationStatus reflects the current state.
    }
}
