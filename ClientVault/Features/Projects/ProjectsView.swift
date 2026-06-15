import SwiftUI

struct ProjectsView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showAddForm = false
    @State private var editingProject: Project?

    private var vm: ProjectsViewModel { env.projectsVM }
    private var clientsVM: ClientsViewModel { env.clientsVM }
    private var paymentsVM: PaymentsViewModel { env.paymentsVM }

    var body: some View {
        @Bindable var vm = vm
        Group {
            if vm.isLoading && vm.projects.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Palette.background)
            } else {
                VStack(spacing: 0) {
                    if !vm.projects.isEmpty {
                        statusFilterBar
                    }
                    let rows = vm.filtered(clients: clientsVM.clients)
                    if rows.isEmpty {
                        emptyState
                    } else {
                        projectList(rows: rows)
                    }
                }
            }
        }
        .background(Palette.background)
        .navigationTitle("Projects")
        .searchable(text: $vm.query, prompt: "Search projects or clients")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.shared.impact(.light)
                    showAddForm = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add project")
            }
        }
        .toolbarBackground(Palette.background, for: .navigationBar)
        .sheet(isPresented: $showAddForm) {
            ProjectFormView(mode: .add, vm: vm, clientsVM: clientsVM)
        }
        .sheet(item: $editingProject) { project in
            ProjectFormView(mode: .edit(project), vm: vm, clientsVM: clientsVM)
        }
        .task { await vm.load() }
        .task { await clientsVM.load() }
        .animation(Motion.spring, value: vm.projects.count)
    }

    // MARK: - Status filter

    private var statusFilterBar: some View {
        @Bindable var vm = vm
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                FilterChip(label: "All", isSelected: vm.statusFilter == nil) {
                    vm.statusFilter = nil
                }
                ForEach(ProjectStatus.allCases) { status in
                    FilterChip(label: status.displayName, isSelected: vm.statusFilter == status) {
                        vm.statusFilter = vm.statusFilter == status ? nil : status
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
        }
        .background(Palette.background)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        @Bindable var vm = vm
        return EmptyStateView(
            icon: "folder",
            title: (vm.query.isEmpty && vm.statusFilter == nil) ? "No projects yet" : "No matches",
            message: (vm.query.isEmpty && vm.statusFilter == nil)
                ? "Projects link to a client and roll up their payments and deadlines."
                : "Try a different search or filter.",
            actionTitle: (vm.query.isEmpty && vm.statusFilter == nil) ? "Add project" : nil,
            action: (vm.query.isEmpty && vm.statusFilter == nil) ? { showAddForm = true } : nil
        )
    }

    // MARK: - List

    private func projectList(rows: [Project]) -> some View {
        List {
            ForEach(rows) { project in
                NavigationLink(value: project) {
                    ProjectRow(project: project, clientName: vm.clientName(for: project.clientId, in: clientsVM.clients))
                }
                .listRowBackground(Palette.surface)
                .listRowSeparatorTint(Palette.surfaceStroke)
                .contextMenu {
                    Button {
                        editingProject = project
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        Task {
                            await vm.delete(id: project.id)
                            Haptics.shared.impact(.medium)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task {
                            await vm.delete(id: project.id)
                            Haptics.shared.impact(.medium)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button {
                        editingProject = project
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(Palette.accentMuted)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationDestination(for: Project.self) { project in
            ProjectDetailView(projectId: project.id, vm: vm, clientsVM: clientsVM, paymentsVM: paymentsVM)
        }
    }
}

// MARK: - Row

private struct ProjectRow: View {
    let project: Project
    let clientName: String?

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(project.name)
                    .font(Typography.headline())
                    .foregroundStyle(Palette.textPrimary)
                if let clientName {
                    Text(clientName)
                        .font(Typography.subheadline())
                        .foregroundStyle(Palette.textSecondary)
                }
                if let due = project.dueDate {
                    DueDateLabel(date: due)
                }
            }
            Spacer()
            ProjectStatusChip(status: project.status)
        }
        .padding(.vertical, Spacing.xs)
    }
}

private struct DueDateLabel: View {
    let date: Date
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private var isOverdue: Bool { date < Date() }

    var body: some View {
        Label(Self.formatter.string(from: date), systemImage: "calendar")
            .font(Typography.caption())
            .foregroundStyle(isOverdue ? Palette.danger : Palette.textTertiary)
    }
}

// MARK: - Filter chip

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Typography.caption())
                .fontWeight(.semibold)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .foregroundStyle(isSelected ? Palette.onAccent : Palette.textSecondary)
                .background(
                    isSelected ? Palette.accent : Palette.surfaceElevated,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .animation(Motion.snappy, value: isSelected)
    }
}
