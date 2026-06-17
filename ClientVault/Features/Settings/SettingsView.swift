import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(SessionStore.self) private var session
    @Environment(EntitlementStore.self) private var entitlements

    @AppStorage("settings.autoLockInterval") private var autoLockInterval: AutoLockInterval = .twoMinutes
    @State private var showDeleteConfirm = false
    @State private var showPaywall = false
    @State private var biometricError: String?

    private var vaultVM: VaultViewModel { env.vaultVM }

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
                    Button("Upgrade to Pro") {
                        Haptics.shared.impact(.light)
                        showPaywall = true
                    }
                }
            }

            Section {
                Toggle("Unlock with Face ID", isOn: biometricBinding)
                    .disabled(vaultVM.viewState != .unlocked)

                if let error = biometricError {
                    Text(error)
                        .font(Typography.footnote())
                        .foregroundStyle(Palette.danger)
                }

                Picker("Auto-lock", selection: $autoLockInterval) {
                    ForEach(AutoLockInterval.allCases) { interval in
                        Text(interval.displayName).tag(interval)
                    }
                }
            } header: {
                Text("Security")
            } footer: {
                if vaultVM.viewState != .unlocked {
                    Text("Unlock the vault to change biometric settings.")
                        .font(Typography.footnote())
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
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private var biometricBinding: Binding<Bool> {
        Binding(
            get: { vaultVM.biometricUnlockEnabled },
            set: { enable in
                biometricError = nil
                do {
                    if enable {
                        try vaultVM.enableBiometricUnlock()
                    } else {
                        try vaultVM.disableBiometricUnlock()
                    }
                    Haptics.shared.success()
                } catch {
                    biometricError = error.localizedDescription
                    Haptics.shared.error()
                }
            }
        )
    }

    private func deleteAccount() {
        Task {
            Haptics.shared.warning()
            try? await env.auth.deleteAccount()
        }
    }

    private static var versionString: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "\(v) (\(b))"
    }
}
