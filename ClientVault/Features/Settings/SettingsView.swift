import SwiftUI
import UserNotifications

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

            integrationsSection

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

    @ViewBuilder
    private var integrationsSection: some View {
        Section("Integrations") {
            pushRow
            githubRow
        }
    }

    @ViewBuilder
    private var pushRow: some View {
        switch env.push.authorizationStatus {
        case .authorized:
            Label("Push notifications: On", systemImage: "bell.fill")
                .foregroundStyle(Palette.success)
        case .denied:
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                Link(destination: settingsURL) {
                    Label("Enable push in Settings", systemImage: "bell.slash")
                        .foregroundStyle(Palette.accent)
                }
            }
        default:
            Button {
                Task { await env.push.requestAuthorizationAndRegister() }
            } label: {
                Label("Enable push notifications", systemImage: "bell")
            }
        }
    }

    @ViewBuilder
    private var githubRow: some View {
        if let profile = env.githubStore.connectedProfile {
            LabeledContent("GitHub", value: "@\(profile.login)")
            Button("Disconnect GitHub", role: .destructive) {
                env.githubStore.disconnect()
            }
        } else {
            Button {
                Task { await env.githubStore.connect() }
            } label: {
                if env.githubStore.isConnecting {
                    HStack(spacing: Spacing.sm) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Connecting…")
                            .foregroundStyle(Palette.textSecondary)
                    }
                } else {
                    Label("Connect GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
            }
            .disabled(env.githubStore.isConnecting)

            if let error = env.githubStore.connectError {
                Text(error)
                    .font(Typography.footnote())
                    .foregroundStyle(Palette.danger)
            }
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
