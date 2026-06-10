import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'entitlement_controller.dart';
import 'plan.dart';

/// `/plans` — Free vs Pro comparison and the purchase entry point. Purchases
/// go live with the cloud launch; until then the CTA explains the timeline.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  BillingTerm _term = BillingTerm.annual;

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on BillingException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entitlement = ref.watch(entitlementProvider);
    final controller = ref.read(entitlementProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Plans')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Take ClientVault everywhere', style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pro adds encrypted cloud sync across your devices. The vault '
            'stays zero-knowledge — the server only ever sees ciphertext.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: SegmentedButton<BillingTerm>(
              segments: const [
                ButtonSegment(
                  value: BillingTerm.monthly,
                  label: Text('Monthly'),
                ),
                ButtonSegment(value: BillingTerm.annual, label: Text('Annual')),
              ],
              selected: {_term},
              onSelectionChanged: (selection) =>
                  setState(() => _term = selection.first),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PlanCard(
            tier: PlanTier.free,
            features: PlanCatalog.freeFeatures,
            isCurrent: !entitlement.isPro,
          ),
          const SizedBox(height: AppSpacing.md),
          _PlanCard(
            tier: PlanTier.pro,
            features: PlanCatalog.proFeatures,
            isCurrent: entitlement.isPro,
            highlighted: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: entitlement.isPro
                ? null
                : () => _run(() => controller.purchase(_term)),
            child: Text(entitlement.isPro ? 'You\'re on Pro' : 'Get Pro'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => _run(controller.restore),
            child: const Text('Restore purchases'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${PlanCatalog.pricingNote} Subscriptions are billed through the '
            'App Store and can be cancelled anytime.',
            style: textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (kDebugMode) ...[
            const SizedBox(height: AppSpacing.lg),
            SwitchListTile(
              title: const Text('DEV — simulate Pro'),
              subtitle: const Text(
                'Debug builds only; exercises the feature gates',
              ),
              value: entitlement.isPro,
              onChanged: (value) =>
                  controller.debugSetTier(value ? PlanTier.pro : PlanTier.free),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.tier,
    required this.features,
    required this.isCurrent,
    this.highlighted = false,
  });

  final PlanTier tier;
  final List<String> features;
  final bool isCurrent;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      shape: highlighted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              side: const BorderSide(color: AppColors.accent, width: 1.5),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(tier.label, style: textTheme.titleLarge),
                const SizedBox(width: AppSpacing.sm),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: const Text(
                      'Current plan',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final feature in features)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: highlighted
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(feature, style: textTheme.bodyMedium)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
