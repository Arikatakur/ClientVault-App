import SwiftUI

/// Vault tab root. Routes to setup, unlock, or list based on VaultViewModel state.
struct VaultView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        let vm = env.vaultVM
        Group {
            switch vm.viewState {
            case .setup:
                VaultSetupView(vm: vm)
            case .locked:
                VaultUnlockView(vm: vm)
            case .unlocked:
                VaultListView(vm: vm)
            }
        }
        .animation(Motion.spring, value: vm.viewState)
        .background(Palette.background)
        .navigationTitle("Vault")
        .toolbarBackground(Palette.background, for: .navigationBar)
    }
}
