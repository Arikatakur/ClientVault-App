import SwiftUI
import CryptoKit
#if canImport(UIKit)
import UIKit
#endif

/// Shows a vault item's decrypted content with a blur-to-clear reveal.
/// Secrets start blurred; tapping reveals them. Copy auto-clears the clipboard
/// after 10 seconds per the security model.
struct VaultItemRevealSheet: View {
    let item: VaultItem
    let vm: VaultViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var itemBody: VaultItemBody?
    @State private var isRevealed = false
    @State private var copiedField: String?
    @State private var editingItem: VaultItem?
    @State private var decryptError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: item.type.iconName)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Palette.vault)
                            .frame(width: 44, height: 44)
                            .background(Palette.vault.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(Typography.headline())
                                .foregroundStyle(Palette.textPrimary)
                            Text(item.type.displayName)
                                .font(Typography.footnote())
                                .foregroundStyle(Palette.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.top, Spacing.sm)

                    if let decryptError {
                        Text(decryptError)
                            .font(Typography.subheadline())
                            .foregroundStyle(Palette.danger)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Palette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                    } else if let decrypted = itemBody {
                        secretFields(decrypted)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .tint(Palette.vault)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
            .background(Palette.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editingItem = item
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .accessibilityLabel("Edit item")
                }
            }
        }
        .onAppear { decrypt() }
        .sheet(item: $editingItem) { editItem in
            AddEditVaultItemView(mode: .edit(editItem), vm: vm)
        }
    }

    @ViewBuilder
    private func secretFields(_ decrypted: VaultItemBody) -> some View {
        if item.type == .totp {
            totpView(seed: decrypted.secret, url: decrypted.url)
        } else {
            standardSecretFields(decrypted)
        }
    }

    // MARK: - TOTP live code view

    private func totpView(seed: String, url: String?) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            let parts = url?.split(separator: "|", maxSplits: 1)
            let issuer = parts.flatMap { $0.count > 0 ? String($0[0]) : nil }
            let account = parts.flatMap { $0.count > 1 ? String($0[1]) : nil }

            if let issuer, !issuer.isEmpty {
                HStack(spacing: Spacing.sm) {
                    Text("Issuer")
                        .font(Typography.footnote())
                        .foregroundStyle(Palette.textSecondary)
                    Text(issuer)
                        .font(Typography.body())
                        .foregroundStyle(Palette.textPrimary)
                }
            }
            if let account, !account.isEmpty {
                HStack(spacing: Spacing.sm) {
                    Text("Account")
                        .font(Typography.footnote())
                        .foregroundStyle(Palette.textSecondary)
                    Text(account)
                        .font(Typography.body())
                        .foregroundStyle(Palette.textPrimary)
                }
            }

            TimelineView(.periodic(from: .now, by: 1)) { _ in
                totpCodeCard(seed: seed)
            }
        }
    }

    private func totpCodeCard(seed: String) -> some View {
        let code = (try? TOTPGenerator.currentCode(seed: seed)) ?? "------"
        let remaining = TOTPGenerator.secondsRemaining
        let fraction = Double(remaining) / 30.0

        return VStack(spacing: Spacing.sm) {
            Text(formattedTOTP(code))
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .foregroundStyle(Palette.textPrimary)
                .contentTransition(.numericText())

            HStack(spacing: Spacing.sm) {
                ProgressView(value: fraction)
                    .tint(fraction > 0.33 ? Palette.vault : Palette.danger)
                    .frame(maxWidth: .infinity)
                Text("\(remaining)s")
                    .font(Typography.caption().monospacedDigit())
                    .foregroundStyle(fraction > 0.33 ? Palette.textSecondary : Palette.danger)
                    .frame(width: 30, alignment: .trailing)
            }

            Button {
                copy(code.filter { $0 != " " }, key: "totp")
            } label: {
                Label(
                    copiedField == "totp" ? "Copied!" : "Copy code",
                    systemImage: copiedField == "totp" ? "checkmark" : "doc.on.doc"
                )
                .font(Typography.subheadline())
                .foregroundStyle(copiedField == "totp" ? Palette.success : Palette.vault)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    private func formattedTOTP(_ code: String) -> String {
        guard code.count == 6 else { return code }
        return "\(code.prefix(3)) \(code.suffix(3))"
    }

    // MARK: - Standard secret fields (non-TOTP)

    @ViewBuilder
    private func standardSecretFields(_ decrypted: VaultItemBody) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if !isRevealed {
                Button {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        isRevealed = true
                    }
                    Haptics.shared.impact(.medium)
                } label: {
                    Label("Tap to reveal", systemImage: "eye")
                        .font(Typography.callout())
                        .foregroundStyle(Palette.vault)
                }
                .buttonStyle(.plain)
            }

            revealField(
                label: secretFieldLabel,
                value: decrypted.secret,
                fieldKey: "secret"
            )

            if let username = decrypted.username, !username.isEmpty {
                revealField(label: "Username", value: username, fieldKey: "username")
            }

            if let url = decrypted.url, !url.isEmpty {
                revealField(label: "URL", value: url, fieldKey: "url")
            }

            if let notes = decrypted.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Notes")
                        .font(Typography.footnote())
                        .foregroundStyle(Palette.textSecondary)
                    Text(notes)
                        .font(Typography.body())
                        .foregroundStyle(Palette.textPrimary)
                        .blur(radius: isRevealed ? 0 : 8)
                        .animation(.easeInOut(duration: 0.35), value: isRevealed)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
            }
        }
    }

    @ViewBuilder
    private func revealField(label: String, value: String, fieldKey: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(Typography.footnote())
                .foregroundStyle(Palette.textSecondary)

            HStack {
                Text(value)
                    .font(Typography.mono())
                    .foregroundStyle(Palette.textPrimary)
                    .blur(radius: isRevealed ? 0 : 8)
                    .animation(.easeInOut(duration: 0.35), value: isRevealed)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    copy(value, key: fieldKey)
                } label: {
                    Image(systemName: copiedField == fieldKey ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 15))
                        .foregroundStyle(copiedField == fieldKey ? Palette.success : Palette.vault)
                        .animation(.easeInOut(duration: 0.2), value: copiedField)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Copy \(label)")
            }
        }
        .padding()
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }

    private var secretFieldLabel: String {
        switch item.type {
        case .password:   return "Password"
        case .apiKey:     return "API Key"
        case .secureNote: return "Note"
        case .card:       return "Card Number"
        case .totp:       return "TOTP Seed"
        case .custom:     return "Secret"
        }
    }

    private func decrypt() {
        do {
            itemBody = try vm.decryptBody(of: item)
        } catch {
            decryptError = error.localizedDescription
        }
    }

    private func copy(_ value: String, key: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = value
        Haptics.shared.success()
        withAnimation { copiedField = key }
        // Auto-clear after 10 seconds per security model.
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if UIPasteboard.general.string == value {
                UIPasteboard.general.string = ""
            }
            withAnimation { if copiedField == key { copiedField = nil } }
        }
        #endif
    }
}
