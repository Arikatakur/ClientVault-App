import SwiftUI

/// Settings. Auto-lock and biometric toggles are local state seams until the
/// Vault/Security phase wires them to the keychain policy; Account and Plan read
/// real session/entitlement state, and Sign out works.
struct SettingsView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(SessionStore.self) private var session
    @Environment(EntitlementStore.self) private var entitlements

    @State private var biometricUnlock = true
    @State private var autoLock: AutoLockInterval = .twoMinutes
    @State private var showDeleteConfirm = false

    var body: some View {
        List {
            Section("Account") {
                if let email = session.user?.email {
                    LabeledContent("Email", value: email)
                }
                LabeledContent("Status", value: session.phase == .authenticated ? "Signed in" : "Signed out")
                Button("Sign out", role: .destructive) {
                    Haptics.shared.warning()
                    env.auth.signOut()
                }
                Button("Delete account", role: .destructive) {
                    showDeleteConfirm = true
                }
            }

            Section("Plan") {
                LabeledContent("Current plan", value: entitlements.plan.displayName)
                if !entitlements.isPro {
                    Button("Upgrade to Pro") { Haptics.shared.impact(.light) }
                }
            }

            Section("Security") {
                Toggle("Unlock with Face ID", isOn: $biometricUnlock)
                Picker("Auto-lock", selection: $autoLock) {
                    ForEach(AutoLockInterval.allCases) { interval in
                        Text(interval.displayName).tag(interval)
                    }
                }
            }

            Section("About") {
                LabeledContent("Version", value: Self.versionString)
                Link("Privacy Policy", destination: URL(string: "https://clientvault.app/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://clientvault.app/terms")!)
                Link("Support", destination: URL(string: "https://clientvault.app/support")!)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.background)
        .navigationTitle("Settings")
        .toolbarBackground(Palette.background, for: .navigationBar)
        .confirmationDialog(
            "Delete your account? This permanently removes your data and can't be undone.",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete account", role: .destructive) { deleteAccount() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func deleteAccount() {
        Task {
            Haptics.shared.warning()
            // On success this signs out, and RootView routes back to sign-in.
            try? await env.auth.deleteAccount()
        }
    }

    private static var versionString: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "\(v) (\(b))"
    }
}

enum AutoLockInterval: String, CaseIterable, Identifiable {
    case immediately, thirtySeconds, twoMinutes, fiveMinutes

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .immediately: return "Immediately"
        case .thirtySeconds: return "After 30s"
        case .twoMinutes: return "After 2 min"
        case .fiveMinutes: return "After 5 min"
        }
    }

    var seconds: TimeInterval {
        switch self {
        case .immediately: return 0
        case .thirtySeconds: return 30
        case .twoMinutes: return 120
        case .fiveMinutes: return 300
        }
    }
}
