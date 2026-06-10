import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Registers the device for APNs and forwards the token to the backend, which
/// stores it per user+device and triggers cross-device pushes via the provider
/// (SNS/Pinpoint in the AWS stack). This is the registration *seam*; sending is
/// a backend concern.
protocol PushRegistering: Sendable {
    /// Asks the system for a remote-notification token. The delegate callback in
    /// the app delegate forwards the result to `didRegister(deviceToken:)`.
    func register()
    /// Uploads the APNs token to the backend (once auth + endpoint exist).
    func didRegister(deviceToken: Data) async
}

final class PushRegistrar: PushRegistering, @unchecked Sendable {
    func register() {
        #if canImport(UIKit)
        Task { @MainActor in
            UIApplication.shared.registerForRemoteNotifications()
        }
        #endif
    }

    func didRegister(deviceToken: Data) async {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        // TODO(push): POST the token to /devices for the signed-in user.
        _ = token
    }
}
