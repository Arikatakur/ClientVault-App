import 'package:go_router/go_router.dart';

import '../../features/account/account_screen.dart';
import '../../features/billing/paywall_screen.dart';
import '../../features/clients/client_detail_screen.dart';
import '../../features/clients/clients_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/github/github_connect_screen.dart';
import '../../features/projects/project_detail_screen.dart';
import '../../features/projects/projects_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/home_shell.dart';
import '../../features/vault/vault_screen.dart';

/// Declarative route tree. A [StatefulShellRoute] gives each bottom-tab its own
/// navigation stack with preserved state, wrapped by [HomeShell]. Detail screens
/// are top-level routes pushed *over* the shell so they present full-screen and
/// return to the originating tab on back.
final GoRouter appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          HomeShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/projects',
              builder: (context, state) => const ProjectsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/clients',
              builder: (context, state) => const ClientsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/vault',
              builder: (context, state) => const VaultScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/clients/:id',
      builder: (context, state) =>
          ClientDetailScreen(clientId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/projects/:id',
      builder: (context, state) =>
          ProjectDetailScreen(projectId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/github',
      builder: (context, state) => const GitHubConnectScreen(),
    ),
    GoRoute(
      path: '/account',
      builder: (context, state) => const AccountScreen(),
    ),
    GoRoute(path: '/plans', builder: (context, state) => const PaywallScreen()),
  ],
);
