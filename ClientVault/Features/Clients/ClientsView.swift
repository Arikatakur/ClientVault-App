import SwiftUI

struct ClientsView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showAddForm = false
    @State private var editingClient: Client?

    private var vm: ClientsViewModel { env.clientsVM }

    var body: some View {
        @Bindable var vm = vm
        Group {
            if vm.isLoading && vm.clients.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Palette.background)
            } else if vm.filtered.isEmpty {
                emptyState
            } else {
                clientList
            }
        }
        .background(Palette.background)
        .navigationTitle("Clients")
        .searchable(text: $vm.query, prompt: "Search clients")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.shared.impact(.light)
                    showAddForm = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add client")
            }
        }
        .toolbarBackground(Palette.background, for: .navigationBar)
        .sheet(isPresented: $showAddForm) {
            ClientFormView(mode: .add, vm: vm)
        }
        .sheet(item: $editingClient) { client in
            ClientFormView(mode: .edit(client), vm: vm)
        }
        .task { await vm.load() }
        .animation(Motion.spring, value: vm.clients.count)
    }

    // MARK: Sub-views

    private var emptyState: some View {
        EmptyStateView(
            icon: "person.2",
            title: vm.query.isEmpty ? "No clients yet" : "No matches",
            message: vm.query.isEmpty
                ? "Add your first client to start tracking projects and payments."
                : "Try a different name or company.",
            actionTitle: vm.query.isEmpty ? "Add client" : nil,
            action: vm.query.isEmpty ? { showAddForm = true } : nil
        )
    }

    private var clientList: some View {
        List {
            ForEach(vm.filtered) { client in
                NavigationLink(value: client) {
                    ClientRow(client: client)
                }
                .listRowBackground(Palette.surface)
                .listRowSeparatorTint(Palette.surfaceStroke)
                .contextMenu {
                    Button {
                        editingClient = client
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        Task {
                            await vm.delete(id: client.id)
                            Haptics.shared.impact(.medium)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task {
                            await vm.delete(id: client.id)
                            Haptics.shared.impact(.medium)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button {
                        editingClient = client
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(Palette.accentMuted)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationDestination(for: Client.self) { client in
            ClientDetailView(clientId: client.id, vm: vm)
        }
        .navigationDestination(for: Project.self) { project in
            ProjectDetailView(projectId: project.id, vm: env.projectsVM, clientsVM: vm, paymentsVM: env.paymentsVM)
        }
    }
}

// MARK: - Row

private struct ClientRow: View {
    let client: Client

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(client.name)
                .font(Typography.headline())
                .foregroundStyle(Palette.textPrimary)
            if let company = client.company {
                Text(company)
                    .font(Typography.subheadline())
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}
