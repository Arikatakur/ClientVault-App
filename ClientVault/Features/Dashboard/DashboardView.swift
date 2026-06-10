import SwiftUI

/// Dashboard — at-a-glance rollups. Tiles show placeholders until cloud CRUD
/// lands (the Clients/Projects/Payments phase); the layout and motion are real.
struct DashboardView: View {
    @Environment(EntitlementStore.self) private var entitlements

    private let columns = [GridItem(.flexible(), spacing: Spacing.md),
                           GridItem(.flexible(), spacing: Spacing.md)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                LazyVGrid(columns: columns, spacing: Spacing.md) {
                    StatTile(title: "Clients", value: "—", icon: "person.2", tint: Palette.accent)
                    StatTile(title: "Projects", value: "—", icon: "folder", tint: Palette.info)
                    StatTile(title: "Outstanding", value: "—", icon: "creditcard", tint: Palette.warning)
                    StatTile(title: "Vault items", value: "—", icon: "lock.shield", tint: Palette.vault)
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
