import SwiftUI

/// The five-tab shell. One `NavigationStack` per tab preserves each tab's
/// navigation state independently, per the premium-UX requirements.
struct MainTabView: View {
    enum Tab: Hashable {
        case dashboard, projects, clients, vault, settings
    }

    @State private var selection: Tab = .dashboard

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack {
                DashboardView()
            }
            .tabItem { Label("Dashboard", systemImage: "square.grid.2x2") }
            .tag(Tab.dashboard)

            NavigationStack {
                ProjectsView()
            }
            .tabItem { Label("Projects", systemImage: "folder") }
            .tag(Tab.projects)

            NavigationStack {
                ClientsView()
            }
            .tabItem { Label("Clients", systemImage: "person.2") }
            .tag(Tab.clients)

            NavigationStack {
                VaultView()
            }
            .tabItem { Label("Vault", systemImage: "lock.shield") }
            .tag(Tab.vault)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(Tab.settings)
        }
    }
}
