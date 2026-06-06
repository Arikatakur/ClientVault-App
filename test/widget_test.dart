// Smoke test: the app boots into the five-tab shell with the dashboard active.
//
// The clients stream is overridden so the test never opens a real on-device
// database (which isn't available in the flutter_test environment).

import 'package:clientvault/app/app.dart';
import 'package:clientvault/data/local/app_database.dart';
import 'package:clientvault/data/providers/database_provider.dart';
import 'package:clientvault/features/vault/vault_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots into the five-tab shell', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clientsStreamProvider.overrideWith(
            (ref) => Stream<List<Client>>.value(const <Client>[]),
          ),
          projectsStreamProvider.overrideWith(
            (ref) => Stream<List<Project>>.value(const <Project>[]),
          ),
          vaultItemsProvider.overrideWith(
            (ref) => Stream<List<VaultItem>>.value(const <VaultItem>[]),
          ),
          paymentsStreamProvider.overrideWith(
            (ref) => Stream<List<Payment>>.value(const <Payment>[]),
          ),
        ],
        child: const ClientVaultApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Bottom navigation with all five destinations.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Clients'), findsWidgets);
    expect(find.text('Vault'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);

    // Dashboard is the initial tab.
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
