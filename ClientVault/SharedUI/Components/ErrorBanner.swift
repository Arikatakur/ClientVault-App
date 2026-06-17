import SwiftUI

/// Inline error banner shown inside a scroll view when a load fails.
/// Provides an optional Retry action that re-attempts the async operation.
struct ErrorBanner: View {
    let message: String
    var retry: (() async -> Void)? = nil

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Palette.danger)

            Text(message)
                .font(Typography.footnote())
                .foregroundStyle(Palette.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let retry {
                Button("Retry") { Task { await retry() } }
                    .font(Typography.caption().weight(.semibold))
                    .foregroundStyle(Palette.accent)
            }
        }
        .padding(Spacing.md)
        .background(
            Palette.danger.opacity(0.10),
            in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .strokeBorder(Palette.danger.opacity(0.25), lineWidth: 1)
        )
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
    }
}
