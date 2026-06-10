import Foundation
import Observation

/// Drives top-level routing: are we signed in, and is the vault unlocked.
///
/// Auth itself (Sign in with Apple / Google) lands in the Auth phase; this store
/// is the seam the shell already routes on. The scaffold starts `authenticated`
/// so the navigation foundation is visible without a backend.
@Observable
final class SessionStore {
    enum Phase: Equatable {
        case unauthenticated
        case authenticated
    }

    /// Vault lock is tracked separately from auth: a signed-in user can still
    /// have a locked vault.
    enum VaultState: Equatable {
        case locked
        case unlocked
    }

    private(set) var phase: Phase
    private(set) var vault: VaultState = .locked
    private(set) var user: UserProfile?

    private let tokenStore: TokenStoring

    /// The scaffold defaulted to `.authenticated`; with auth wired the app starts
    /// `.unauthenticated` and `restore()` promotes it if a session exists.
    init(tokenStore: TokenStoring, phase: Phase = .unauthenticated) {
        self.tokenStore = tokenStore
        self.phase = phase
    }

    /// Sign-in completed with a known user.
    func completeSignIn(user: UserProfile?) {
        self.user = user
        phase = .authenticated
    }

    /// Restored an existing session where we don't (yet) have profile details.
    func markAuthenticated() {
        phase = .authenticated
    }

    func signOut() {
        tokenStore.clear()
        user = nil
        vault = .locked
        phase = .unauthenticated
    }

    func vaultUnlocked() { vault = .unlocked }
    func lockVault() { vault = .locked }

    /// Called when the app enters the background. The vault auto-locks so a
    /// returning session must re-authenticate to the vault.
    func onEnteredBackground() {
        lockVault()
    }
}
