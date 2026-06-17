import SwiftUI

/// First-time vault creation. Prompts for a new vault password, derives the key
/// hierarchy, and transitions straight to the unlocked list on success.
struct VaultSetupView: View {
    let vm: VaultViewModel

    @State private var password = ""
    @State private var confirm = ""
    @State private var showError = false
    @State private var errorText = ""

    private var canCreate: Bool {
        password.count >= 8 && password == confirm && !vm.isBusy
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(Palette.vault)

                    Text("Create Your Vault")
                        .font(Typography.title())
                        .foregroundStyle(Palette.textPrimary)

                    Text("Set a strong vault password. Your secrets are encrypted on this device before they ever leave it — this password cannot be recovered if lost.")
                        .font(Typography.subheadline())
                        .foregroundStyle(Palette.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.xxl)

                VStack(spacing: Spacing.md) {
                    SecureField("Vault password (8+ characters)", text: $password)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .stroke(Palette.surfaceStroke, lineWidth: 1)
                        )

                    SecureField("Confirm password", text: $confirm)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .stroke(passwordMatchStroke, lineWidth: 1)
                        )

                    if showError {
                        Text(errorText)
                            .font(Typography.footnote())
                            .foregroundStyle(Palette.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if vm.isBusy {
                    ProgressView("Deriving key — this takes a moment…")
                        .foregroundStyle(Palette.textSecondary)
                        .tint(Palette.vault)
                } else {
                    PrimaryButton("Create Vault") {
                        Task { await createVault() }
                    }
                    .disabled(!canCreate)
                    .opacity(canCreate ? 1 : 0.5)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .background(Palette.background)
    }

    private var passwordMatchStroke: Color {
        if confirm.isEmpty { return Palette.surfaceStroke }
        return confirm == password ? Palette.success : Palette.danger
    }

    private func createVault() async {
        guard password == confirm else {
            showError = true; errorText = "Passwords don't match."; return
        }
        guard password.count >= 8 else {
            showError = true; errorText = "Password must be at least 8 characters."; return
        }
        showError = false
        do {
            Haptics.shared.impact(.medium)
            try await vm.setupVault(password: password)
            Haptics.shared.success()
        } catch {
            showError = true
            errorText = error.localizedDescription
            Haptics.shared.error()
        }
    }
}
