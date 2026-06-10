import SwiftUI

/// Projects tab. Status filters and per-project payments arrive in later phases.
struct ProjectsView: View {
    @State private var query = ""

    var body: some View {
        EmptyStateView(
            icon: "folder",
            title: "No projects yet",
            message: "Projects link to a client and roll up their payments and deadlines.",
            actionTitle: "Add project",
            action: { Haptics.shared.impact(.light) }
        )
        .background(Palette.background)
        .navigationTitle("Projects")
        .searchable(text: $query, prompt: "Search projects")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.shared.impact(.light)
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add project")
            }
        }
        .toolbarBackground(Palette.background, for: .navigationBar)
    }
}
