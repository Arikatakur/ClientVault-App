import SwiftUI

/// Top-level router. Switches between the auth flow and the main app based on
/// session phase. Vault locking is handled within the Vault feature.
struct RootView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        Group {
            switch session.phase {
            case .authenticated:
                MainTabView()
            case .unauthenticated:
                AuthView()
            }
        }
        .animation(Motion.spring, value: session.phase)
    }
}
