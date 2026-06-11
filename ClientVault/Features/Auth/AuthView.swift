import SwiftUI
import AuthenticationServices

/// Sign-in screen. Apple uses the official `SignInWithAppleButton` (App Review
/// expects it); both providers route their result through `AppEnvironment.auth`,
/// which handles the nonce, backend exchange, and session.
struct AuthView: View {
    @Environment(AppEnvironment.self) private var env

    @State private var isLoading = false
    @State private var errorMessage: String?

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
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = env.auth.appleRequestNonce()
                    } onCompletion: { result in
                        // Parse synchronously (no actor hop, no ASAuthorization
                        // capture), then finish on the main actor.
                        let outcome = env.auth.makeAppleCredential(from: result)
                        Task { @MainActor in finishApple(outcome) }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                    .disabled(isLoading)

                    Button {
                        Task { @MainActor in await finishGoogle() }
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
                    .disabled(isLoading)

                    if isLoading {
                        ProgressView()
                            .tint(Palette.accent)
                            .padding(.top, Spacing.xs)
                    } else if let errorMessage {
                        Text(errorMessage)
                            .font(Typography.footnote())
                            .foregroundStyle(Palette.danger)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }

                    Text("By continuing you agree to the Terms and Privacy Policy.")
                        .font(Typography.caption())
                        .foregroundStyle(Palette.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, Spacing.xs)
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxl)
                .animation(Motion.snappy, value: isLoading)
                .animation(Motion.snappy, value: errorMessage)
            }
        }
    }

    @MainActor
    private func finishApple(_ outcome: Result<ProviderCredential, AuthError>) {
        switch outcome {
        case .failure(.cancelled):
            break // user backed out — stay silent
        case .failure(let error):
            errorMessage = error.userMessage
            Haptics.shared.error()
        case .success(let credential):
            Task { @MainActor in
                await complete { try await env.auth.completeSignIn(with: credential) }
            }
        }
    }

    @MainActor
    private func finishGoogle() async {
        await complete { try await env.auth.signInWithGoogle() }
    }

    /// Shared loading/error wrapper. On success the session flips to authenticated
    /// and `RootView` swaps in the tab shell, so there's nothing to dismiss here.
    @MainActor
    private func complete(_ operation: () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        do {
            try await operation()
        } catch AuthError.cancelled {
            // User backed out — stay silent.
        } catch let error as AuthError {
            errorMessage = error.userMessage
            Haptics.shared.error()
        } catch {
            errorMessage = "Something went wrong. Please try again."
            Haptics.shared.error()
        }
        isLoading = false
    }
}
