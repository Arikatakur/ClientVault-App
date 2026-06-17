import SwiftUI

struct ClientDetailView: View {
    let clientId: UUID
    let vm: ClientsViewModel

    @Environment(AppEnvironment.self) private var env
    @State private var showEditForm = false
    @State private var newNoteBody = ""
    @State private var showAddNoteField = false
    @State private var editingNote: ClientNote?

    private var clientNotesVM: ClientNotesViewModel { env.clientNotesVM }

    /// Derived from VM so edits immediately reflect here without popping.
    private var client: Client? {
        vm.clients.first { $0.id == clientId }
    }

    private var linkedProjects: [Project] {
        env.projectsVM.projects.filter { $0.clientId == clientId && $0.deletedAt == nil }
    }

    var body: some View {
        Group {
            if let client {
                content(client: client)
            } else {
                // Deleted while the detail was open
                ContentUnavailableView("Client not found", systemImage: "person.2.slash")
                    .background(Palette.background)
            }
        }
        .background(Palette.background)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEditForm = true }
                    .foregroundStyle(Palette.accent)
                    .disabled(client == nil)
            }
        }
        .toolbarBackground(Palette.background, for: .navigationBar)
        .sheet(isPresented: $showEditForm) {
            if let client {
                ClientFormView(mode: .edit(client), vm: vm)
            }
        }
        .task { await env.projectsVM.load() }
        .task { await clientNotesVM.load(clientId: clientId) }
        .navigationTitle(client?.name ?? "")
        .sheet(item: $editingNote) { note in
            EditClientNoteSheet(note: note, vm: clientNotesVM)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(client: Client) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                contactCard(client: client)
                notesSection(clientId: client.id)
                projectsSection
            }
            .padding(Spacing.lg)
        }
    }

    // MARK: - Contact card

    private func contactCard(client: Client) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Spacing.md) {
                if let company = client.company {
                    InfoRow(icon: "building.2", label: "Company", value: company)
                }
                if let email = client.email {
                    InfoRow(icon: "envelope", label: "Email", value: email)
                }
                if let phone = client.phone {
                    InfoRow(icon: "phone", label: "Phone", value: phone)
                }
                if let notes = client.notes {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Label("Notes", systemImage: "note.text")
                            .font(Typography.caption())
                            .foregroundStyle(Palette.textSecondary)
                        Text(notes)
                            .font(Typography.body())
                            .foregroundStyle(Palette.textPrimary)
                    }
                }
                if client.company == nil && client.email == nil
                    && client.phone == nil && client.notes == nil {
                    Text("No contact info added.")
                        .font(Typography.subheadline())
                        .foregroundStyle(Palette.textSecondary)
                }
            }
        }
    }

    // MARK: - Notes section

    @ViewBuilder
    private func notesSection(clientId: UUID) -> some View {
        let notes = clientNotesVM.notes(for: clientId)
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                SectionHeader(title: "Notes")
                Spacer()
                Button {
                    Haptics.shared.impact(.light)
                    withAnimation { showAddNoteField.toggle() }
                } label: {
                    Image(systemName: showAddNoteField ? "minus.circle" : "plus.circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Palette.accent)
                }
                .accessibilityLabel(showAddNoteField ? "Cancel add note" : "Add note")
            }

            if showAddNoteField {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    TextEditor(text: $newNoteBody)
                        .frame(minHeight: 70)
                        .font(Typography.body())
                        .foregroundStyle(Palette.textPrimary)
                        .padding(Spacing.sm)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                    Button {
                        submitNewNote(clientId: clientId)
                    } label: {
                        Text("Add Note")
                            .font(Typography.subheadline().weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                newNoteBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? Palette.accent.opacity(0.4)
                                    : Palette.accent,
                                in: RoundedRectangle(cornerRadius: Radius.sm)
                            )
                    }
                    .disabled(newNoteBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            if notes.isEmpty && !showAddNoteField {
                Text("No notes yet.")
                    .font(Typography.subheadline())
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.horizontal, Spacing.xs)
            } else {
                ForEach(notes) { note in
                    ClientNoteRow(note: note)
                        .onTapGesture { editingNote = note }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task {
                                    await clientNotesVM.delete(id: note.id, clientId: clientId)
                                    Haptics.shared.impact(.medium)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button { editingNote = note } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                Task { await clientNotesVM.delete(id: note.id, clientId: clientId) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }

    private func submitNewNote(clientId: UUID) {
        let trimmed = newNoteBody.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Task {
            await clientNotesVM.add(clientId: clientId, body: trimmed)
            Haptics.shared.success()
        }
        newNoteBody = ""
        withAnimation { showAddNoteField = false }
    }

    // MARK: - Projects section

    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Projects")
            if linkedProjects.isEmpty {
                Text("No projects linked to this client.")
                    .font(Typography.subheadline())
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.horizontal, Spacing.xs)
            } else {
                ForEach(linkedProjects) { project in
                    NavigationLink(value: project) {
                        LinkedProjectRow(project: project)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Client note row

private struct ClientNoteRow: View {
    let note: ClientNote

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(note.body)
                .font(Typography.body())
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(Typography.caption())
                .foregroundStyle(Palette.textTertiary)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .strokeBorder(Palette.surfaceStroke, lineWidth: 1)
        )
    }
}

// MARK: - Edit note sheet

private struct EditClientNoteSheet: View {
    let note: ClientNote
    let vm: ClientNotesViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var body_ = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Note") {
                    TextEditor(text: $body_)
                        .frame(minHeight: 120)
                        .listRowBackground(Palette.surfaceElevated)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Palette.background)
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await vm.update(note, body: body_)
                            Haptics.shared.success()
                            dismiss()
                        }
                    }
                    .disabled(body_.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear { body_ = note.body }
    }
}

// MARK: - Helpers

private struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Palette.accent)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(Typography.caption())
                    .foregroundStyle(Palette.textSecondary)
                Text(value)
                    .font(Typography.body())
                    .foregroundStyle(Palette.textPrimary)
            }
        }
    }
}

private struct LinkedProjectRow: View {
    let project: Project

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(project.name)
                    .font(Typography.headline())
                    .foregroundStyle(Palette.textPrimary)
                ProjectStatusChip(status: project.status)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Palette.textTertiary)
        }
        .padding(Spacing.md)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .strokeBorder(Palette.surfaceStroke, lineWidth: 1)
        )
    }
}
