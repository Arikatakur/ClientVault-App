import 'package:flutter/material.dart';

import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';

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
    );
  }
}
