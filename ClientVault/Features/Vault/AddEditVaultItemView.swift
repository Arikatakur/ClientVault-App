import SwiftUI

struct AddEditVaultItemView: View {
    enum Mode {
        case add
        case edit(VaultItem)
    }

    let mode: Mode
    let vm: VaultViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var type: VaultItemType = .password
    @State private var secret = ""
    @State private var username = ""
    @State private var url = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !secret.isEmpty &&
        !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Title", text: $title)
                        .listRowBackground(Palette.surfaceElevated)

                    Picker("Type", selection: $type) {
                        ForEach(VaultItemType.allCases) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                    .listRowBackground(Palette.surfaceElevated)
                }

                Section("Secret") {
                    SecureField(secretLabel, text: $secret)
                        .textContentType(isEditing ? .password : .newPassword)
                        .listRowBackground(Palette.surfaceElevated)
                }

                if type == .password || type == .apiKey {
                    Section("Details") {
                        if type == .password {
                            TextField("Username", text: $username)
                                .textInputAutocapitalization(.never)
                                .listRowBackground(Palette.surfaceElevated)
                        }
                        TextField("URL", text: $url)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .listRowBackground(Palette.surfaceElevated)
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .listRowBackground(Palette.surfaceElevated)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(Typography.footnote())
                            .foregroundStyle(Palette.danger)
                            .listRowBackground(Palette.surfaceElevated)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .navigationTitle(isEditing ? "Edit Item" : "New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView().tint(Palette.vault)
                    } else {
                        Button("Save") { Task { await save() } }
                            .disabled(!canSave)
                    }
                }
            }
        }
        .onAppear { populateIfEditing() }
    }

    private var secretLabel: String {
        switch type {
        case .password:   return "Password"
        case .apiKey:     return "API Key"
        case .secureNote: return "Note"
        case .card:       return "Card number"
        case .custom:     return "Secret"
        }
    }

    private func populateIfEditing() {
        guard case .edit(let item) = mode else { return }
        title = item.title
        type = item.type
        guard let body = try? vm.decryptBody(of: item) else { return }
        secret = body.secret
        username = body.username ?? ""
        url = body.url ?? ""
        notes = body.notes ?? ""
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        errorMessage = nil
        let body = VaultItemBody(
            secret: secret,
            username: username.isEmpty ? nil : username,
            url: url.isEmpty ? nil : url,
            notes: notes.isEmpty ? nil : notes
        )
        do {
            switch mode {
            case .add:
                try await vm.addItem(title: title, type: type, body: body)
            case .edit(let item):
                try await vm.updateItem(item, title: title, body: body)
            }
            Haptics.shared.success()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.shared.error()
        }
    }
}
