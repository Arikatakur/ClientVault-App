import SwiftUI
import AuthenticationServices

/// Sign-in screen. The Apple/Google flows and backend token validation land in
/// the Auth phase; the buttons and layout exist now so routing is complete.
struct AuthView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                VStack(spacing: Spacing.md) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 64, weight: .semibold))
                        .foregroundStyle(Palette.accent)
                    Text("ClientVault")
                        .font(Typography.largeTitle())
                        .foregroundStyle(Palette.textPrimary)
                    Text("Clients, projects, payments, and an encrypted vault — across your devices.")
                        .font(Typography.subheadline())
                        .foregroundStyle(Palette.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                }

                Spacer()

                VStack(spacing: Spacing.md) {
                    SignInWithAppleButton(.signIn) { _ in
                        // Request scopes here in the Auth phase.
                    } onCompletion: { _ in
                        // TODO(auth): validate Apple identity token with backend,
                        // provision/lookup user, then mark the session signed in.
                        Haptics.shared.success()
                        session.signedIn()
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))

                    Button {
                        // TODO(auth): GoogleSignIn SDK + backend token validation.
                        Haptics.shared.success()
                        session.signedIn()
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "g.circle.fill")
                            Text("Continue with Google").font(Typography.headline())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .foregroundStyle(Palette.textPrimary)
                        .background(Palette.surfaceElevated, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Text("By continuing you agree to the Terms and Privacy Policy.")
                        .font(Typography.caption())
                        .foregroundStyle(Palette.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, Spacing.xs)
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxl)
            }
        }
    }
}
