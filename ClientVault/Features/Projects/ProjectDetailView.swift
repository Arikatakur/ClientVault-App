import SwiftUI

struct ProjectDetailView: View {
    let projectId: UUID
    let vm: ProjectsViewModel
    let clientsVM: ClientsViewModel
    let paymentsVM: PaymentsViewModel

    @State private var showEditForm = false
    @State private var showAddPaymentForm = false
    @State private var editingPayment: Payment?

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
        .sheet(isPresented: $showAddPaymentForm) {
            PaymentFormView(mode: .add(projectId: projectId), vm: paymentsVM)
        }
        .sheet(item: $editingPayment) { payment in
            PaymentFormView(mode: .edit(payment), vm: paymentsVM)
        }
        .task { await paymentsVM.load() }
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
                paymentsSection(project: project)
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

    // MARK: - Payments

    @ViewBuilder
    private func paymentsSection(project: Project) -> some View {
        let rows = paymentsVM.payments(for: project.id)
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                SectionHeader(title: "Payments")
                Spacer()
                Button {
                    Haptics.shared.impact(.light)
                    showAddPaymentForm = true
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Palette.accent)
                }
                .accessibilityLabel("Add payment")
            }

            if !rows.isEmpty {
                let totals = paymentsVM.formattedTotal(for: project.id)
                paymentsRollup(totals: totals)
            }

            if rows.isEmpty {
                Text("No payments recorded.")
                    .font(Typography.subheadline())
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.horizontal, Spacing.xs)
            } else {
                ForEach(rows) { payment in
                    PaymentRow(payment: payment, formatted: paymentsVM.formatted(payment))
                        .contextMenu {
                            Button { editingPayment = payment } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                Task {
                                    await paymentsVM.delete(id: payment.id)
                                    Haptics.shared.impact(.medium)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .onTapGesture { editingPayment = payment }
                }
            }
        }
    }

    private func paymentsRollup(totals: (invoiced: String, paid: String, outstanding: String)) -> some View {
        CardContainer {
            HStack {
                rollupItem(label: "Invoiced", value: totals.invoiced)
                Divider().frame(height: 32)
                rollupItem(label: "Paid", value: totals.paid)
                Divider().frame(height: 32)
                rollupItem(label: "Outstanding", value: totals.outstanding)
            }
        }
    }

    private func rollupItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Typography.headline())
                .foregroundStyle(Palette.textPrimary)
            Text(label)
                .font(Typography.caption())
                .foregroundStyle(Palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Payment row

private struct PaymentRow: View {
    let payment: Payment
    let formatted: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(formatted)
                    .font(Typography.headline())
                    .foregroundStyle(Palette.textPrimary)
                if let due = payment.dueDate {
                    Label(due.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        .font(Typography.caption())
                        .foregroundStyle(payment.isOverdue ? Palette.danger : Palette.textTertiary)
                }
                if let note = payment.note {
                    Text(note)
                        .font(Typography.caption())
                        .foregroundStyle(Palette.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            PaymentStatusBadge(payment: payment)
        }
        .padding(Spacing.md)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .strokeBorder(Palette.surfaceStroke, lineWidth: 1)
        )
    }
}
