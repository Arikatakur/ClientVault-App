import SwiftUI

/// Settings. Auto-lock and biometric toggles are local state seams until the
/// Vault/Security phase wires them to the keychain policy; Account and Plan read
/// real session/entitlement state, and Sign out works.
struct SettingsView: View {
    @Environment(SessionStore.self) private var session
    @Environment(EntitlementStore.self) private var entitlements

    @State private var biometricUnlock = true
    @State private var autoLock: AutoLockInterval = .twoMinutes

    var body: some View {
        List {
            Section("Account") {
                LabeledContent("Status", value: session.phase == .authenticated ? "Signed in" : "Signed out")
                Button("Sign out", role: .destructive) {
                    Haptics.shared.warning()
                    session.signOut()
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
