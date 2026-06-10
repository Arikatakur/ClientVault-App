import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Covers the UI the instant the app stops being the active foreground app —
/// the moment iOS snapshots it for the app switcher — so client data and
/// vault content never appear in the switcher or behind system sheets.
///
/// The cover appears with no animation (the snapshot is taken immediately on
/// backgrounding) and fades away on return. The Android half of this
/// protection (FLAG_SECURE) is deferred with the rest of the Android wiring.
class PrivacyShield extends StatefulWidget {
  const PrivacyShield({super.key, required this.child});

  final Widget child;

  @override
  State<PrivacyShield> createState() => _PrivacyShieldState();
}

class _PrivacyShieldState extends State<PrivacyShield> {
  late final AppLifecycleListener _listener;
  bool _covered = false;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onStateChange: _onStateChange);
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  void _onStateChange(AppLifecycleState state) {
    final covered = state != AppLifecycleState.resumed;
    if (covered != _covered) {
      setState(() => _covered = covered);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        IgnorePointer(
          ignoring: !_covered,
          child: AnimatedOpacity(
            opacity: _covered ? 1 : 0,
            duration: _covered
                ? Duration.zero
                : const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: const _PrivacyCover(),
          ),
        ),
      ],
    );
  }
}

class _PrivacyCover extends StatelessWidget {
  const _PrivacyCover();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: const BoxDecoration(
                color: AppColors.accentSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 34,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'ClientVault',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
