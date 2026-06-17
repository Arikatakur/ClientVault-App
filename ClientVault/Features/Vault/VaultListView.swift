import SwiftUI

/// Vault unlocked — lists all encrypted items. Tapping an item opens the reveal sheet.
struct VaultListView: View {
    let vm: VaultViewModel

    @State private var showAddForm = false
    @State private var selectedItem: VaultItem?
    @State private var editingItem: VaultItem?
    @State private var query = ""

    private var filtered: [VaultItem] {
        guard !query.isEmpty else { return vm.items }
        let q = query.lowercased()
        return vm.items.filter {
            $0.title.lowercased().contains(q) ||
            $0.type.displayName.lowercased().contains(q)
        }
    }

    var body: some View {
        Group {
            if vm.items.isEmpty {
                EmptyStateView(
                    icon: "key.horizontal",
                    title: "No vault items yet",
                    message: "Store passwords, API keys, cards and secure notes — encrypted end-to-end.",
                    actionTitle: "Add item",
                    action: {
                        Haptics.shared.impact(.light)
                        showAddForm = true
                    }
                )
            } else {
                List {
                    ForEach(filtered) { item in
                        Button {
                            Haptics.shared.impact(.light)
                            selectedItem = item
                        } label: {
                            VaultItemRow(item: item)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Palette.surface)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task {
                                    Haptics.shared.impact(.rigid)
                                    try? await vm.deleteItem(item)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button {
                                editingItem = item
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                Task { try? await vm.deleteItem(item) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Palette.background)
                .searchable(text: $query, prompt: "Search vault")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Haptics.shared.impact(.rigid)
                    vm.lock()
                } label: {
                    Image(systemName: "lock")
                }
                .accessibilityLabel("Lock vault")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.shared.impact(.light)
                    showAddForm = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add vault item")
            }
        }
        .sheet(isPresented: $showAddForm) {
            AddEditVaultItemView(mode: .add, vm: vm)
        }
        .sheet(item: $editingItem) { item in
            AddEditVaultItemView(mode: .edit(item), vm: vm)
        }
        .sheet(item: $selectedItem) { item in
            VaultItemRevealSheet(item: item, vm: vm)
        }
    }
}

private struct VaultItemRow: View {
    let item: VaultItem

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: item.type.iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Palette.vault)
                .frame(width: 36, height: 36)
                .background(Palette.vault.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(Typography.body())
                    .foregroundStyle(Palette.textPrimary)
                Text(item.type.displayName)
                    .font(Typography.footnote())
                    .foregroundStyle(Palette.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Palette.textTertiary)
        }
        .padding(.vertical, Spacing.xs)
    }
}

extension VaultItemType {
    var iconName: String {
        switch self {
        case .password:   return "key.horizontal"
        case .apiKey:     return "chevron.left.forwardslash.chevron.right"
        case .secureNote: return "note.text"
        case .card:       return "creditcard"
        case .custom:     return "lock.rectangle"
        }
    }
}
