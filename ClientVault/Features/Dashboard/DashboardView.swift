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

    // MARK: - Derived data

    private var overduePayments: [Payment] { paymentsVM.overduePayments }

    private var upcomingProjects: [Project] {
        let cutoff = Date().addingTimeInterval(7 * 24 * 3600)
        return projectsVM.projects.filter { project in
            guard let due = project.dueDate, project.deletedAt == nil else { return false }
            return due > Date() && due <= cutoff && project.status != .completed
        }
        .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private func projectName(for payment: Payment) -> String? {
        projectsVM.projects.first { $0.id == payment.projectId }?.name
    }

    private func clientName(for project: Project) -> String? {
        clientsVM.clients.first { $0.id == project.clientId }?.name
    }

    // MARK: - Body

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
                        icon: overduePayments.isEmpty
                            ? "creditcard"
                            : "creditcard.trianglebadge.exclamationmark",
                        tint: overduePayments.isEmpty ? Palette.warning : Palette.danger
                    )
                    StatTile(
                        title: "Vault items",
                        value: vaultVM.viewState == .unlocked ? "\(vaultVM.items.count)" : "—",
                        icon: "lock.shield",
                        tint: Palette.vault
                    )
                }

                if !overduePayments.isEmpty {
                    overdueSection
                }

                if !upcomingProjects.isEmpty {
                    upcomingSection
                }

                if clientsVM.clients.isEmpty && projectsVM.projects.isEmpty {
                    getStartedCard
                }
            }
            .padding(Spacing.lg)
        }
        .background(Palette.background)
        .navigationTitle("Dashboard")
        .toolbarBackground(Palette.background, for: .navigationBar)
        .refreshable {
            async let a: () = clientsVM.load()
            async let b: () = projectsVM.load()
            async let c: () = paymentsVM.load()
            _ = await (a, b, c)
        }
        .task { await clientsVM.load() }
        .task { await projectsVM.load() }
        .task { await paymentsVM.load() }
    }

    // MARK: - Overdue section

    private var overdueSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Overdue Payments", systemImage: "exclamationmark.circle.fill")
                .font(Typography.headline())
                .foregroundStyle(Palette.danger)

            ForEach(overduePayments.prefix(3)) { payment in
                OverduePaymentRow(
                    payment: payment,
                    formatted: paymentsVM.formatted(payment),
                    projectName: projectName(for: payment)
                )
            }
            if overduePayments.count > 3 {
                Text("+\(overduePayments.count - 3) more overdue")
                    .font(Typography.caption())
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.horizontal, Spacing.xs)
            }
        }
    }

    // MARK: - Due soon section

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Due This Week", systemImage: "calendar.badge.clock")
                .font(Typography.headline())
                .foregroundStyle(Palette.warning)

            ForEach(upcomingProjects) { project in
                UpcomingProjectRow(project: project, clientName: clientName(for: project))
            }
        }
    }

    // MARK: - Get started card

    private var getStartedCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Get started")
                    .font(Typography.headline())
                    .foregroundStyle(Palette.textPrimary)
                Text("Add a client, then create a project and track payments — all in one place.")
                    .font(Typography.subheadline())
                    .foregroundStyle(Palette.textSecondary)
            }
        }
    }
}

// MARK: - Stat tile

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
                    .contentTransition(.numericText())
                    .animation(Motion.snappy, value: value)
                Text(title)
                    .font(Typography.footnote())
                    .foregroundStyle(Palette.textSecondary)
            }
        }
    }
}

// MARK: - Overdue row

private struct OverduePaymentRow: View {
    let payment: Payment
    let formatted: String
    let projectName: String?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                if let name = projectName {
                    Text(name)
                        .font(Typography.subheadline())
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(1)
                }
                if let due = payment.dueDate {
                    Text("Due \(due.formatted(date: .abbreviated, time: .omitted))")
                        .font(Typography.caption())
                        .foregroundStyle(Palette.danger)
                }
            }
            Spacer()
            Text(formatted)
                .font(Typography.headline())
                .foregroundStyle(Palette.danger)
        }
        .padding(Spacing.md)
        .background(
            Palette.danger.opacity(0.08),
            in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .strokeBorder(Palette.danger.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Upcoming row

private struct UpcomingProjectRow: View {
    let project: Project
    let clientName: String?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(Typography.subheadline())
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                if let name = clientName {
                    Text(name)
                        .font(Typography.caption())
                        .foregroundStyle(Palette.textSecondary)
                }
            }
            Spacer()
            if let due = project.dueDate {
                Text(due.formatted(date: .abbreviated, time: .omitted))
                    .font(Typography.caption())
                    .foregroundStyle(Palette.warning)
            }
        }
        .padding(Spacing.md)
        .background(
            Palette.warning.opacity(0.08),
            in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .strokeBorder(Palette.warning.opacity(0.2), lineWidth: 1)
        )
    }
}
