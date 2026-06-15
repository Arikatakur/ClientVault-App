import SwiftUI

struct ProjectDetailView: View {
    let projectId: UUID
    let vm: ProjectsViewModel
    let clientsVM: ClientsViewModel

    @State private var showEditForm = false

    /// Derived from VM so edits immediately reflect here without popping.
    private var project: Project? {
        vm.projects.first { $0.id == projectId }
    }

    private var clientName: String? {
        guard let project else { return nil }
        return vm.clientName(for: project.clientId, in: clientsVM.clients)
    }

    var body: some View {
        Group {
            if let project {
                content(project: project)
            } else {
                ContentUnavailableView("Project not found", systemImage: "folder.badge.questionmark")
                    .background(Palette.background)
            }
        }
        .background(Palette.background)
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle(project?.name ?? "")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEditForm = true }
                    .foregroundStyle(Palette.accent)
                    .disabled(project == nil)
            }
        }
        .toolbarBackground(Palette.background, for: .navigationBar)
        .sheet(isPresented: $showEditForm) {
            if let project {
                ProjectFormView(mode: .edit(project), vm: vm, clientsVM: clientsVM)
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private func content(project: Project) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                headerCard(project: project)
                if project.summary != nil || project.githubRepo != nil {
                    detailsCard(project: project)
                }
            }
            .padding(Spacing.lg)
        }
    }

    // MARK: - Header (status + client + due date)

    private func headerCard(project: Project) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    ProjectStatusChip(status: project.status)
                    Spacer()
                }

                if let name = clientName {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "person.2")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Palette.accent)
                        Text(name)
                            .font(Typography.subheadline())
                            .foregroundStyle(Palette.textSecondary)
                    }
                }

                if let due = project.dueDate {
                    let overdue = due < Date()
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "calendar")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(overdue ? Palette.danger : Palette.accent)
                        Text("Due \(due.formatted(date: .abbreviated, time: .omitted))")
                            .font(Typography.subheadline())
                            .foregroundStyle(overdue ? Palette.danger : Palette.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Details (summary + GitHub)

    private func detailsCard(project: Project) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Spacing.md) {
                if let summary = project.summary {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Label("Summary", systemImage: "text.alignleft")
                            .font(Typography.caption())
                            .foregroundStyle(Palette.textSecondary)
                        Text(summary)
                            .font(Typography.body())
                            .foregroundStyle(Palette.textPrimary)
                    }
                }
                if let repo = project.githubRepo {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Palette.accent)
                        Text(repo)
                            .font(Typography.subheadline())
                            .foregroundStyle(Palette.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}
