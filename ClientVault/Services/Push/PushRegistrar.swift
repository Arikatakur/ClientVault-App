import Foundation
import Observation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

/// Manages APNs registration and tracks authorization status.
/// `@MainActor @Observable` so views can reactively show the current permission state.
@MainActor @Observable
final class PushRegistrar: @unchecked Sendable {
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var deviceToken: String?

    /// Refreshes `authorizationStatus` from UNUserNotificationCenter.
    /// Call on foreground and after requesting authorization.
    func checkStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// Requests notification permission (alert, badge, sound) and, if granted,
    /// registers with APNs. The system token callback arrives in AppDelegate and
    /// is forwarded here via `didRegister(deviceToken:)`.
    func requestAuthorizationAndRegister() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            authorizationStatus = settings.authorizationStatus
            if granted {
                #if canImport(UIKit)
                UIApplication.shared.registerForRemoteNotifications()
                #endif
            }
        } catch {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            authorizationStatus = settings.authorizationStatus
        }
    }

    /// Called by AppDelegate after the system issues an APNs device token.
    /// `nonisolated` so AppDelegate can call it from a synchronous, non-isolated context.
    nonisolated func didRegister(deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task { @MainActor [self] in
            self.deviceToken = token
            // TODO(push): POST token to /devices for the signed-in user.
        }
    }
}
