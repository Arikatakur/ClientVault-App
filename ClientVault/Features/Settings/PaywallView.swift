import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 56, weight: .semibold))
                            .foregroundStyle(Palette.accent)

                        Text("ClientVault Pro")
                            .font(Typography.title())
                            .foregroundStyle(Palette.textPrimary)

                        Text("Unlock the full power of ClientVault — unlimited clients, seamless cloud sync, and secure file attachments.")
                            .font(Typography.subheadline())
                            .foregroundStyle(Palette.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Spacing.xxl)

                    VStack(spacing: Spacing.sm) {
                        PaywallFeatureRow(
                            icon: "person.2.fill",
                            title: "Unlimited clients",
                            description: "Grow without limits — add as many clients as you need."
                        )
                        PaywallFeatureRow(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Cloud sync",
                            description: "Your data available on every device, automatically."
                        )
                        PaywallFeatureRow(
                            icon: "paperclip",
                            title: "Secure attachments",
                            description: "Attach files to clients, projects, and vault items."
                        )
                    }

                    purchaseSection

                    if let error = entitlements.purchaseError {
                        Text(error)
                            .font(Typography.footnote())
                            .foregroundStyle(Palette.danger)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
            .background(Palette.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .task { await entitlements.loadProducts() }
        .onChange(of: entitlements.isPro) { _, isPro in
            if isPro { dismiss() }
        }
    }

    @ViewBuilder
    private var purchaseSection: some View {
        if entitlements.isLoadingProducts {
            ProgressView()
                .tint(Palette.accent)
                .frame(maxWidth: .infinity)
        } else if let product = entitlements.products.first {
            VStack(spacing: Spacing.sm) {
                PrimaryButton(title: "Subscribe — \(product.displayPrice)/month") {
                    Task { await entitlements.purchase(product) }
                }
                Button("Restore purchases") {
                    Task { await entitlements.restorePurchases() }
                }
                .font(Typography.callout())
                .foregroundStyle(Palette.textSecondary)
                .buttonStyle(.plain)
            }
        } else {
            VStack(spacing: Spacing.sm) {
                Text("Product not available right now.")
                    .font(Typography.callout())
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
                Button("Restore purchases") {
                    Task { await entitlements.restorePurchases() }
                }
                .font(Typography.callout())
                .foregroundStyle(Palette.vault)
                .buttonStyle(.plain)
            }
        }
    }
}

private struct PaywallFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Palette.accent)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.callout())
                    .foregroundStyle(Palette.textPrimary)
                Text(description)
                    .font(Typography.footnote())
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer()
        }
        .padding()
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }
}
