/// Plan tiers per the Cloud + Subscriptions plan: Free = local-only,
/// single-device, core CRM + vault. Pro = cloud sync, multi-device,
/// unlimited clients/projects.
enum PlanTier {
  free('Free'),
  pro('Pro');

  const PlanTier(this.label);

  final String label;
}

/// Billing period offered on the paywall. Store products (StoreKit 2 via
/// RevenueCat) attach to these once pricing is decided.
enum BillingTerm { monthly, annual }

/// What each tier includes — single source of truth for the paywall and any
/// upgrade prompts.
abstract final class PlanCatalog {
  PlanCatalog._();

  static const List<String> freeFeatures = [
    'Clients, projects & payments',
    'Encrypted vault on this device',
    'GitHub repo integration',
    'File attachments & PDF viewer',
    'Due-date reminders',
  ];

  static const List<String> proFeatures = [
    'Everything in Free',
    'Cloud sync & encrypted backup',
    'Use ClientVault on all your devices',
    'Unlimited clients & projects',
    'Priority support',
  ];

  /// Pricing is an open question in the plan; the paywall shows this until
  /// store products exist.
  static const String pricingNote = 'Pricing is announced at launch.';
}

/// The user's current subscription standing. [source] records which system
/// granted it ('local' until RevenueCat is wired, then 'revenuecat';
/// 'debug' for the dev-only override).
class Entitlement {
  const Entitlement({required this.tier, required this.source});

  static const Entitlement localFree = Entitlement(
    tier: PlanTier.free,
    source: 'local',
  );

  final PlanTier tier;
  final String source;

  bool get isPro => tier == PlanTier.pro;
}

/// A user-facing purchase/restore failure ([message] is shown verbatim).
class BillingException implements Exception {
  const BillingException(this.message);

  final String message;

  @override
  String toString() => message;
}
