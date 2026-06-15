import SwiftUI

/// Pill badge showing a project's status with a matching tint. Used on list
/// rows, detail headers, and inside client detail project sections.
struct ProjectStatusChip: View {
    let status: ProjectStatus

    var body: some View {
        Text(status.displayName)
            .font(Typography.caption())
            .fontWeight(.semibold)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .foregroundStyle(tint)
            .background(tint.opacity(0.15), in: Capsule())
    }

    private var tint: Color {
        switch status {
        case .lead:   return Palette.textSecondary
        case .active: return Palette.success
        case .paused: return Palette.warning
        case .done:   return Palette.accent
        }
    }
}
