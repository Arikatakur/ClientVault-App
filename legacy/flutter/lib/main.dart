import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Share one provider container so the notification service initialized here
  // is the same instance the rest of the app uses.
  final container = ProviderContainer();
  await container
      .read(notificationServiceProvider)
      .init(
        onSelectNotification: (payload) {
          if (payload != null && payload.isNotEmpty) appRouter.go(payload);
        },
      );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ClientVaultApp(),
    ),
  );
}
