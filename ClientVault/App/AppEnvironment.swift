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
    let auth: AuthServicing
    let entitlements: EntitlementStore
    let haptics: HapticsServicing
    let keychain: KeychainStoring
    let crypto: CryptoService
    let api: APIClient
    let push: PushRegistering
    let notifications: LocalNotificationScheduling
    let clientsVM: ClientsViewModel
    let projectsVM: ProjectsViewModel
    let paymentsVM: PaymentsViewModel
    let vaultVM: VaultViewModel

    init(
        config: AppConfig,
        session: SessionStore,
        auth: AuthServicing,
        entitlements: EntitlementStore,
        haptics: HapticsServicing,
        keychain: KeychainStoring,
        crypto: CryptoService,
        api: APIClient,
        push: PushRegistering,
        notifications: LocalNotificationScheduling,
        clientsVM: ClientsViewModel,
        projectsVM: ProjectsViewModel,
        paymentsVM: PaymentsViewModel,
        vaultVM: VaultViewModel
    ) {
        self.config = config
        self.session = session
        self.auth = auth
        self.entitlements = entitlements
        self.haptics = haptics
        self.keychain = keychain
        self.crypto = crypto
        self.api = api
        self.push = push
        self.notifications = notifications
        self.clientsVM = clientsVM
        self.projectsVM = projectsVM
        self.paymentsVM = paymentsVM
        self.vaultVM = vaultVM
    }

    /// Wires the production implementations together.
    @MainActor
    static func live() -> AppEnvironment {
        let config = AppConfig.current
        let keychain = KeychainStore(service: config.keychainService)
        let tokenStore = TokenStore(keychain: keychain)
        let api = URLSessionAPIClient(baseURL: config.apiBaseURL, tokenProvider: tokenStore)
        let session = SessionStore(tokenStore: tokenStore)
        let auth = LiveAuthService(api: api, tokenStore: tokenStore, session: session, config: config)

        let clientRepo: ClientRepositing = config.hasBackend
            ? LiveClientRepository(api: api)
            : InMemoryClientRepository()
        let projectRepo: ProjectRepositing = config.hasBackend
            ? LiveProjectRepository(api: api)
            : InMemoryProjectRepository()
        let paymentRepo: PaymentRepositing = config.hasBackend
            ? LivePaymentRepository(api: api)
            : InMemoryPaymentRepository()
        let vaultRepo: VaultRepositing = config.hasBackend
            ? LiveVaultRepository(api: api)
            : InMemoryVaultRepository()
        let crypto = AESGCMCrypto()

        let storeKit: StoreKitServicing = config.hasBackend
            ? LiveStoreKitService()
            : DevStoreKitService()

        return AppEnvironment(
            config: config,
            session: session,
            auth: auth,
            entitlements: EntitlementStore(storeKit: storeKit),
            haptics: Haptics.shared,
            keychain: keychain,
            crypto: crypto,
            api: api,
            push: PushRegistrar(),
            notifications: LocalNotificationScheduler(),
            clientsVM: ClientsViewModel(repo: clientRepo),
            projectsVM: ProjectsViewModel(repo: projectRepo),
            paymentsVM: PaymentsViewModel(repo: paymentRepo),
            vaultVM: VaultViewModel(
                crypto: crypto,
                keychain: keychain,
                repo: vaultRepo,
                session: session
            )
        )
    }
}
