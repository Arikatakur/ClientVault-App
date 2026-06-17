import SwiftUI
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

@main
struct ClientVaultApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var environment = AppEnvironment.live()
    @Environment(\.scenePhase) private var scenePhase

    /// When true, the branded privacy shield covers the whole UI. Driven by
    /// scene phase so the app-switcher snapshot never captures sensitive content.
    @State private var isObscured = false

    /// Timestamp recorded when the app enters background. Used to implement
    /// interval-based vault auto-lock: on foreground return, if the elapsed time
    /// exceeds the user's chosen interval, the vault is locked.
    @State private var backgroundedAt: Date?

    /// Mirrors the user's auto-lock preference from Settings. Shared via
    /// UserDefaults so changes in SettingsView take effect immediately here.
    @AppStorage("settings.autoLockInterval") private var autoLockInterval: AutoLockInterval = .twoMinutes

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .environment(environment.session)
                .environment(environment.entitlements)
                .tint(Palette.accent)
                .preferredColorScheme(.dark)
                .overlay {
                    if isObscured {
                        PrivacyShieldView()
                            // No transition: the shield must appear/disappear
                            // instantly, never animating the content into view.
                            .transition(.identity)
                    }
                }
                .onChange(of: scenePhase, initial: true) { _, newPhase in
                    isObscured = (newPhase != .active)
                    switch newPhase {
                    case .background:
                        backgroundedAt = Date()
                        // Lock immediately only for the "Immediately" setting.
                        // For longer intervals, the DEK stays in memory while the
                        // app is suspended (privacy shield covers the snapshot).
                        if autoLockInterval == .immediately {
                            environment.vaultVM.lock()
                        }
                    case .active:
                        // Lock on foreground return if enough time has elapsed.
                        if let t = backgroundedAt,
                           Date.now.timeIntervalSince(t) >= autoLockInterval.seconds {
                            environment.vaultVM.lock()
                        }
                        backgroundedAt = nil
                        // Refresh push status in case the user changed it in Settings app.
                        Task { await environment.push.checkStatus() }
                    default:
                        break
                    }
                }
                .task {
                    // Wire AppDelegate push-token callback to PushRegistrar.
                    // didRegister is nonisolated so it's safe to call from this closure.
                    appDelegate.onDeviceToken = { data in
                        environment.push.didRegister(deviceToken: data)
                    }
                    await environment.auth.restore()
                    await environment.push.checkStatus()
                }
                .onOpenURL { url in
                    #if canImport(GoogleSignIn)
                    GIDSignIn.sharedInstance.handle(url)
                    #endif
                }
        }
    }
}
