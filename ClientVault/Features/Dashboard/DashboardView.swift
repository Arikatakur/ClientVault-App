import SwiftUI

struct DashboardView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(EntitlementStore.self) private var entitlements

    private var clientsVM: ClientsViewModel { env.clientsVM }
    private var projectsVM: ProjectsViewModel { env.projectsVM }
    private var paymentsVM: PaymentsViewModel { env.paymentsVM }
    private var vaultVM: VaultViewModel { env.vaultVM }

    private let columns = [GridItem(.flexible(), spacing: Spacing.md),
                           GridItem(.flexible(), spacing: Spacing.md)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                LazyVGrid(columns: columns, spacing: Spacing.md) {
                    StatTile(
                        title: "Clients",
                        value: "\(clientsVM.clients.count)",
                        icon: "person.2",
                        tint: Palette.accent
                    )
                    StatTile(
                        title: "Projects",
                        value: "\(projectsVM.projects.filter { $0.deletedAt == nil }.count)",
                        icon: "folder",
                        tint: Palette.info
                    )
                    StatTile(
                        title: "Outstanding",
                        value: "\(paymentsVM.outstandingCount)",
                        icon: "creditcard",
                        tint: Palette.warning
                    )
                    StatTile(
                        title: "Vault items",
                        value: vaultVM.viewState == .unlocked ? "\(vaultVM.items.count)" : "—",
                        icon: "lock.shield",
                        tint: Palette.vault
                    )
                }

                CardContainer {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Welcome to ClientVault")
                            .font(Typography.headline())
                            .foregroundStyle(Palette.textPrimary)
                        Text("Your clients, projects, payments and encrypted vault — synced across devices. Live data arrives as each module ships.")
                            .font(Typography.subheadline())
                            .foregroundStyle(Palette.textSecondary)
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .background(Palette.background)
        .navigationTitle("Dashboard")
        .toolbarBackground(Palette.background, for: .navigationBar)
        .task { await clientsVM.load() }
        .task { await projectsVM.load() }
        .task { await paymentsVM.load() }
    }
}

private struct StatTile: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        CardContainer(padding: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(tint)
                Text(value)
                    .font(Typography.title())
                    .foregroundStyle(Palette.textPrimary)
                Text(title)
                    .font(Typography.footnote())
                    .foregroundStyle(Palette.textSecondary)
            }
        }
    }
}
