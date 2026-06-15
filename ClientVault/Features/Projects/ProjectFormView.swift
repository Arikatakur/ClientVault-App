import SwiftUI

enum ProjectFormMode {
    case add
    case edit(Project)

    var title: String {
        switch self {
        case .add:  "New Project"
        case .edit: "Edit Project"
        }
    }

    var existing: Project? {
        if case .edit(let p) = self { return p }
        return nil
    }
}

struct ProjectFormView: View {
    let mode: ProjectFormMode
    let vm: ProjectsViewModel
    let clientsVM: ClientsViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedClientId: UUID?
    @State private var status: ProjectStatus = .lead
    @State private var hasDueDate = false
    @State private var dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var summary = ""
    @State private var githubRepo = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !isSaving
    }

    var body: some View {
        NavigationStack {
            List {
                // Name
                Section {
                    TextField("Project name", text: $name)
                        .font(Typography.body())
                } header: {
                    Text("Name").font(Typography.caption()).foregroundStyle(Palette.textSecondary)
                } footer: {
                    if name.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("Required").foregroundStyle(Palette.danger).font(Typography.caption())
                    }
                }

                // Client + Status
                Section {
                    Picker("Client", selection: $selectedClientId) {
                        Text("None").tag(Optional<UUID>.none)
                        ForEach(clientsVM.clients) { client in
                            Text(client.name).tag(Optional(client.id))
                        }
                    }
                    Picker("Status", selection: $status) {
                        ForEach(ProjectStatus.allCases) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                } header: {
                    Text("Details").font(Typography.caption()).foregroundStyle(Palette.textSecondary)
                }

                // Due date
                Section {
                    Toggle("Set due date", isOn: $hasDueDate.animation(Motion.snappy))
                    if hasDueDate {
                        DatePicker(
                            "Due date",
                            selection: $dueDate,
                            displayedComponents: .date
                        )
                        .tint(Palette.accent)
                    }
                } header: {
                    Text("Timeline").font(Typography.caption()).foregroundStyle(Palette.textSecondary)
                }

                // Summary
                Section {
                    TextField("Optional summary…", text: $summary, axis: .vertical)
                        .font(Typography.body())
                        .lineLimit(3...8)
                } header: {
                    Text("Summary").font(Typography.caption()).foregroundStyle(Palette.textSecondary)
                }

                // GitHub
                Section {
                    TextField("owner/repo", text: $githubRepo)
                        .font(Typography.body())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                } header: {
                    Text("GitHub Repo (optional)").font(Typography.caption()).foregroundStyle(Palette.textSecondary)
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
        guard let p = mode.existing else { return }
        name             = p.name
        selectedClientId = p.clientId
        status           = p.status
        summary          = p.summary  ?? ""
        githubRepo       = p.githubRepo ?? ""
        if let due = p.dueDate {
            hasDueDate = true
            dueDate    = due
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        if case .edit(let existing) = mode {
            var updated = existing
            updated.name       = name.trimmingCharacters(in: .whitespaces)
            updated.clientId   = selectedClientId
            updated.status     = status
            updated.dueDate    = hasDueDate ? dueDate : nil
            updated.summary    = blank(summary)
            updated.githubRepo = blank(githubRepo)
            updated.updatedAt  = Date()
            await vm.update(updated)
        } else {
            await vm.add(
                name:      name.trimmingCharacters(in: .whitespaces),
                clientId:  selectedClientId,
                status:    status,
                dueDate:   hasDueDate ? dueDate : nil,
                summary:   blank(summary),
                githubRepo: blank(githubRepo)
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
