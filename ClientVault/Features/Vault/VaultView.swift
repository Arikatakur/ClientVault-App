import SwiftUI

/// Vault tab. The lock/unlock surface is here; the crypto + cloud ciphertext
/// storage and reveal sheet land in the Vault phase. Until then this shows the
/// locked state so the security posture is visible from day one.
struct VaultView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        Group {
            switch session.vault {
            case .locked:
                EmptyStateView(
                    icon: "lock.shield",
                    title: "Vault locked",
                    message: "Unlock with Face ID or your vault password to view encrypted items. Secrets are encrypted on this device before they ever leave it.",
                    actionTitle: "Unlock",
                    action: {
                        Haptics.shared.success()
                        session.vaultUnlocked()
                    }
                )
            case .unlocked:
                EmptyStateView(
                    icon: "key.horizontal",
                    title: "No vault items yet",
                    message: "Store passwords, API keys, cards and secure notes — encrypted end-to-end.",
                    actionTitle: "Add item",
                    action: { Haptics.shared.impact(.light) }
                )
            }
        }
        .animation(Motion.spring, value: session.vault)
        .background(Palette.background)
        .navigationTitle("Vault")
        .toolbar {
            if session.vault == .unlocked {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Haptics.shared.impact(.rigid)
                        session.lockVault()
                    } label: {
                        Image(systemName: "lock")
                    }
                    .accessibilityLabel("Lock vault")
                }
            }
        }
        .toolbarBackground(Palette.background, for: .navigationBar)
    }
}
