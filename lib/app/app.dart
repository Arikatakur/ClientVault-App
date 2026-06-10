import 'package:flutter/material.dart';

import '../core/router/app_router.dart';
import '../core/security/privacy_shield.dart';
import '../core/theme/app_theme.dart';
import '../features/notifications/notifications_bootstrap.dart';
import '../features/vault/auto_lock_scope.dart';

/// Root application widget.
///
/// Dark-first per the design system; a light theme toggle is deferred to a
/// later version. Routing is delegated to [appRouter] (go_router).
class ClientVaultApp extends StatelessWidget {
  const ClientVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ClientVault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
      builder: (context, child) => PrivacyShield(
        child: AutoLockScope(
          child: NotificationsBootstrap(
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
