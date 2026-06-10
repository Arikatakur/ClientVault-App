import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'billing_repository.dart';
import 'plan.dart';

/// Rebind to the RevenueCat adapter when store products exist.
final billingRepositoryProvider = Provider<BillingRepository>(
  (ref) => const LocalBillingRepository(),
);

final entitlementProvider =
    NotifierProvider<EntitlementController, Entitlement>(
      EntitlementController.new,
    );

/// Holds the user's plan. Purchase/restore rethrow [BillingException] so the
/// paywall can show the message.
class EntitlementController extends Notifier<Entitlement> {
  late BillingRepository _repo;

  @override
  Entitlement build() {
    _repo = ref.watch(billingRepositoryProvider);
    _load();
    return Entitlement.localFree;
  }

  Future<void> _load() async {
    state = await _repo.currentEntitlement();
  }

  Future<void> purchase(BillingTerm term) async {
    state = await _repo.purchase(term);
  }

  Future<void> restore() async {
    state = await _repo.restore();
  }

  /// Debug-build-only override so feature gates can be exercised before the
  /// store exists. No-op in profile/release builds.
  void debugSetTier(PlanTier tier) {
    if (!kDebugMode) return;
    state = Entitlement(tier: tier, source: 'debug');
  }
}
