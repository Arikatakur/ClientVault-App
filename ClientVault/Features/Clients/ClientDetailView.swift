import SwiftUI

struct ClientDetailView: View {
    let clientId: UUID
    let vm: ClientsViewModel

    @Environment(AppEnvironment.self) private var env
    @State private var showEditForm = false

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
        .navigationTitle(client?.name ?? "")
    }

    // MARK: - Content

    @ViewBuilder
    private func content(client: Client) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                contactCard(client: client)
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
