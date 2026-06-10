import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'entitlement_controller.dart';

/// Lets the caller through when the user is on Pro; otherwise shows the
/// paywall and re-checks after it closes. Cloud features call this before
/// doing anything Pro-only:
///
/// ```dart
/// if (!await ensurePro(context, ref)) return;
/// ```
///
/// The server independently validates entitlements for cloud operations —
/// this gate is UX, not security.
Future<bool> ensurePro(BuildContext context, WidgetRef ref) async {
  if (ref.read(entitlementProvider).isPro) return true;
  await GoRouter.of(context).push('/plans');
  return ref.read(entitlementProvider).isPro;
}
