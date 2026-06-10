import Foundation
import Observation

/// Composition root / lightweight DI container.
///
/// Holds the app's long-lived services as protocol types so features depend on
/// abstractions, not concrete implementations (keeps things testable and avoids
/// "god objects"). Construct once at launch via `AppEnvironment.live()` and
/// inject through the SwiftUI environment.
@Observable
final class AppEnvironment {
    let config: AppConfig
    let session: SessionStore
    let entitlements: EntitlementStore
    let haptics: HapticsServicing
    let keychain: KeychainStoring
    let crypto: CryptoService
    let api: APIClient
    let push: PushRegistering
    let notifications: LocalNotificationScheduling

    init(
        config: AppConfig,
        session: SessionStore,
        entitlements: EntitlementStore,
        haptics: HapticsServicing,
        keychain: KeychainStoring,
        crypto: CryptoService,
        api: APIClient,
        push: PushRegistering,
        notifications: LocalNotificationScheduling
    ) {
        self.config = config
        self.session = session
        self.entitlements = entitlements
        self.haptics = haptics
        self.keychain = keychain
        self.crypto = crypto
        self.api = api
        self.push = push
        self.notifications = notifications
    }

    /// Wires the production implementations together.
    static func live() -> AppEnvironment {
        let config = AppConfig.current
        let keychain = KeychainStore(service: config.keychainService)
        let tokenStore = TokenStore(keychain: keychain)
        let api = URLSessionAPIClient(baseURL: config.apiBaseURL, tokenProvider: tokenStore)
        let session = SessionStore(tokenStore: tokenStore)

        return AppEnvironment(
            config: config,
            session: session,
            entitlements: EntitlementStore(),
            haptics: Haptics.shared,
            keychain: keychain,
            crypto: AESGCMCrypto(),
            api: api,
            push: PushRegistrar(),
            notifications: LocalNotificationScheduler()
        )
    }
}
