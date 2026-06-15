import SwiftUI

enum ClientFormMode {
    case add
    case edit(Client)

    var title: String {
        switch self {
        case .add:  "New Client"
        case .edit: "Edit Client"
        }
    }

    var existing: Client? {
        if case .edit(let c) = self { return c }
        return nil
    }
}

struct ClientFormView: View {
    let mode: ClientFormMode
    let vm: ClientsViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var company = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !isSaving
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Full name", text: $name)
                        .font(Typography.body())
                } header: {
                    Text("Name").font(Typography.caption()).foregroundStyle(Palette.textSecondary)
                } footer: {
                    if name.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("Required").foregroundStyle(Palette.danger).font(Typography.caption())
                    }
                }

                Section {
                    TextField("Company", text: $company)
                        .font(Typography.body())
                    TextField("Email", text: $email)
                        .font(Typography.body())
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Phone", text: $phone)
                        .font(Typography.body())
                        .keyboardType(.phonePad)
                } header: {
                    Text("Contact").font(Typography.caption()).foregroundStyle(Palette.textSecondary)
                }

                Section {
                    TextField("Optional notes…", text: $notes, axis: .vertical)
                        .font(Typography.body())
                        .lineLimit(3...8)
                } header: {
                    Text("Notes").font(Typography.caption()).foregroundStyle(Palette.textSecondary)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(Typography.footnote())
                            .foregroundStyle(Palette.danger)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Palette.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isSaving {
                        ProgressView().tint(Palette.accent)
                    } else {
                        Button("Save") {
                            Task { await save() }
                        }
                        .font(Typography.headline())
                        .foregroundStyle(canSave ? Palette.accent : Palette.textTertiary)
                        .disabled(!canSave)
                    }
                }
            }
        }
        .onAppear(perform: populate)
    }

    private func populate() {
        guard let c = mode.existing else { return }
        name    = c.name
        company = c.company ?? ""
        email   = c.email   ?? ""
        phone   = c.phone   ?? ""
        notes   = c.notes   ?? ""
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        if case .edit(let existing) = mode {
            var updated = existing
            updated.name    = name.trimmingCharacters(in: .whitespaces)
            updated.company = blank(company)
            updated.email   = blank(email)
            updated.phone   = blank(phone)
            updated.notes   = blank(notes)
            updated.updatedAt = Date()
            await vm.update(updated)
        } else {
            await vm.add(
                name:    name.trimmingCharacters(in: .whitespaces),
                company: blank(company),
                email:   blank(email),
                phone:   blank(phone),
                notes:   blank(notes)
            )
        }
        if let err = vm.errorMessage {
            errorMessage = err
            isSaving = false
        } else {
            Haptics.shared.success()
            dismiss()
        }
    }

    private func blank(_ s: String) -> String? {
        s.trimmingCharacters(in: .whitespaces).isEmpty ? nil : s.trimmingCharacters(in: .whitespaces)
    }
}
