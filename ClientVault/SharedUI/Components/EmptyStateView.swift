import SwiftUI

/// Friendly, branded empty state with a single obvious action — used across
/// every list before data exists. Empty→populated transitions animate via the
/// motion spec at the call site.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(Palette.accent)
                .padding(Spacing.lg)
                .background(
                    Circle().fill(Palette.surfaceElevated)
                )
                .accessibilityHidden(true)

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(Typography.headline())
                    .foregroundStyle(Palette.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(Typography.subheadline())
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, action: action)
                    .padding(.top, Spacing.sm)
                    .fixedSize()
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        icon: "person.2",
        title: "No clients yet",
        message: "Add your first client to start tracking projects and payments.",
        actionTitle: "Add client",
        action: {}
    )
    .background(Palette.background)
}
