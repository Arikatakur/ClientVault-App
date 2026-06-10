import 'package:clientvault/features/billing/billing_repository.dart';
import 'package:clientvault/features/billing/entitlement_controller.dart';
import 'package:clientvault/features/billing/plan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalBillingRepository', () {
    const repo = LocalBillingRepository();

    test('everyone is on Free before the store exists', () async {
      final entitlement = await repo.currentEntitlement();
      expect(entitlement.tier, PlanTier.free);
      expect(entitlement.isPro, isFalse);
    });

    test('purchase and restore explain that the store is not live', () {
      expect(
        () => repo.purchase(BillingTerm.annual),
        throwsA(isA<BillingException>()),
      );
      expect(repo.restore, throwsA(isA<BillingException>()));
    });
  });

  group('EntitlementController', () {
    test('starts on Free and the debug override flips the tier', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(entitlementProvider).isPro, isFalse);

      // Tests run in debug mode, so the override is active.
      container.read(entitlementProvider.notifier).debugSetTier(PlanTier.pro);
      expect(container.read(entitlementProvider).isPro, isTrue);
      expect(container.read(entitlementProvider).source, 'debug');

      container.read(entitlementProvider.notifier).debugSetTier(PlanTier.free);
      expect(container.read(entitlementProvider).isPro, isFalse);
    });

    test('purchase surfaces the BillingException from the repository', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container
            .read(entitlementProvider.notifier)
            .purchase(BillingTerm.monthly),
        throwsA(isA<BillingException>()),
      );
    });
  });
}
