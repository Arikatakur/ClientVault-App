import SwiftUI

/// Vault locked screen. Offers password entry and, if enrolled, biometric unlock.
struct VaultUnlockView: View {
    let vm: VaultViewModel

    @State private var password = ""
    @State private var showError = false
    @State private var errorText = ""

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(Palette.vault)

                    Text("Vault Locked")
                        .font(Typography.title())
                        .foregroundStyle(Palette.textPrimary)

                    Text("Unlock with your vault password to view encrypted items.")
                        .font(Typography.subheadline())
                        .foregroundStyle(Palette.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.xxl)

                VStack(spacing: Spacing.md) {
                    SecureField("Vault password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .stroke(Palette.surfaceStroke, lineWidth: 1)
                        )
                        .onSubmit { Task { await unlock() } }

                    if showError {
                        Text(errorText)
                            .font(Typography.footnote())
                            .foregroundStyle(Palette.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                VStack(spacing: Spacing.sm) {
                    if vm.isBusy {
                        ProgressView("Unlocking…")
                            .foregroundStyle(Palette.textSecondary)
                            .tint(Palette.vault)
                    } else {
                        PrimaryButton("Unlock") {
                            Task { await unlock() }
                        }
                        .disabled(password.isEmpty)
                        .opacity(password.isEmpty ? 0.5 : 1)

                        if vm.biometricUnlockEnabled {
                            Button {
                                Task { await unlockBiometric() }
                            } label: {
                                Label("Use Face ID / Touch ID", systemImage: "faceid")
                                    .font(Typography.callout())
                                    .foregroundStyle(Palette.vault)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .background(Palette.background)
        .task {
            // Auto-attempt biometric on first appearance if enrolled.
            if vm.biometricUnlockEnabled {
                await unlockBiometric()
            }
        }
    }

    private func unlock() async {
        guard !password.isEmpty else { return }
        showError = false
        do {
            Haptics.shared.impact(.medium)
            try await vm.unlock(password: password)
            Haptics.shared.success()
        } catch {
            showError = true
            errorText = error.localizedDescription
            password = ""
            Haptics.shared.error()
        }
    }

    private func unlockBiometric() async {
        do {
            try await vm.unlockWithBiometrics()
            Haptics.shared.success()
        } catch {
            // Biometric failure is silent — fall back to the password field.
        }
    }
}
