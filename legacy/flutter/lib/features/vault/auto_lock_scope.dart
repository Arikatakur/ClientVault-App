import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'vault_controller.dart';

/// Wraps the whole app to enforce auto-lock. It locks the vault when the app is
/// backgrounded (per the configured timeout) and after the same idle period in
/// the foreground. Any pointer interaction resets the idle timer.
///
/// Reads vault providers lazily (only in callbacks), so it never forces the
/// vault to initialize just by being mounted.
class AutoLockScope extends ConsumerStatefulWidget {
  const AutoLockScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AutoLockScope> createState() => _AutoLockScopeState();
}

class _AutoLockScopeState extends ConsumerState<AutoLockScope>
    with WidgetsBindingObserver {
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(vaultControllerProvider.notifier);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _idleTimer?.cancel();
      notifier.onPaused();
    } else if (state == AppLifecycleState.resumed) {
      notifier.onResumed();
      _resetIdleTimer();
    }
  }

  void _onInteraction(PointerDownEvent _) => _resetIdleTimer();

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    final timeout = ref.read(lockTimeoutProvider);
    if (timeout <= 0) return; // 0 = lock on background only, no idle timer
    if (ref.read(vaultControllerProvider) != VaultStatus.unlocked) return;
    _idleTimer = Timer(Duration(seconds: timeout), () {
      ref.read(vaultControllerProvider.notifier).lock();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onInteraction,
      child: widget.child,
    );
  }
}
