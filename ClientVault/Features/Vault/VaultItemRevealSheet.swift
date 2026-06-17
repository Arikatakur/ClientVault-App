import SwiftUI
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
