import 'plan.dart';

/// Contract for the store-billing backend. The RevenueCat (purchases_flutter)
/// adapter implements this once the RevenueCat project and App Store Connect
/// subscription products exist; until then the local implementation keeps
/// everyone on Free. Server-side entitlement validation (webhook → Lambda)
/// comes with the AWS backend — the client never gates on its own say-so
/// for cloud features.
abstract class BillingRepository {
  Future<Entitlement> currentEntitlement();

  /// Starts the store purchase flow and returns the resulting entitlement.
  Future<Entitlement> purchase(BillingTerm term);

  /// Restores purchases made on another install of the same store account.
  Future<Entitlement> restore();
}

/// Pre-store billing: everyone is on Free, and purchase attempts explain why.
class LocalBillingRepository implements BillingRepository {
  const LocalBillingRepository();

  static const String _pendingMessage =
      'Subscriptions open with the ClientVault Cloud launch — everything in '
      'the app today stays free.';

  @override
  Future<Entitlement> currentEntitlement() async => Entitlement.localFree;

  @override
  Future<Entitlement> purchase(BillingTerm term) =>
      throw const BillingException(_pendingMessage);

  @override
  Future<Entitlement> restore() =>
      throw const BillingException('No purchases to restore yet.');
}
