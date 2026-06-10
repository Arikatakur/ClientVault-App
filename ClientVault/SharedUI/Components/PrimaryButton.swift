import SwiftUI

/// The app's primary call-to-action. Fires a light haptic on tap for tactility.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.shared.impact(.light)
            action()
        } label: {
            HStack(spacing: Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(Palette.onAccent)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(Typography.headline())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.xl)
            .foregroundStyle(Palette.onAccent)
            .background(Palette.accent, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Add client", systemImage: "plus", action: {})
        PrimaryButton(title: "Loading", isLoading: true, action: {})
    }
    .padding()
    .background(Palette.background)
}
