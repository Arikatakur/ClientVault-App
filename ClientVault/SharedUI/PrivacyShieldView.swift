import SwiftUI

/// Branded cover shown whenever the app is not active (inactive/background).
///
/// Two jobs: (1) make the iOS app-switcher snapshot show this instead of any
/// vault/data content, and (2) provide a calm "locked" affordance on return.
/// It must render instantly with no animation — see `ClientVaultApp`.
struct PrivacyShieldView: View {
    var body: some View {
        ZStack {
            Palette.background
                .ignoresSafeArea()

            // Subtle brand gradient so the cover feels intentional, not like a crash.
            RadialGradient(
                colors: [Palette.accent.opacity(0.18), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(Palette.accent)
                    .accessibilityHidden(true)

                Text("ClientVault")
                    .font(Typography.title())
                    .foregroundStyle(Palette.textPrimary)

                Text("Locked")
                    .font(Typography.subheadline())
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("ClientVault is locked")
    }
}

#Preview {
    PrivacyShieldView()
}
