import SwiftUI

/// Clients tab. List + search UX is wired; live data arrives with cloud CRUD.
struct ClientsView: View {
    @State private var query = ""

    var body: some View {
        EmptyStateView(
            icon: "person.2",
            title: "No clients yet",
            message: "Add your first client to start tracking projects and payments.",
            actionTitle: "Add client",
            action: { Haptics.shared.impact(.light) }
        )
        .background(Palette.background)
        .navigationTitle("Clients")
        .searchable(text: $query, prompt: "Search clients")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.shared.impact(.light)
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add client")
            }
        }
        .toolbarBackground(Palette.background, for: .navigationBar)
    }
}
