import SwiftUI

@main
struct ClientVaultApp: App {
    @State private var environment = AppEnvironment.live()
    @Environment(\.scenePhase) private var scenePhase

    /// When true, the branded privacy shield covers the whole UI. Driven by
    /// scene phase so the app-switcher snapshot never captures sensitive content.
    @State private var isObscured = false

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
                    if newPhase == .background {
                        environment.session.onEnteredBackground()
                    }
                }
        }
    }
}
