import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:drive_tracker/features/splash/splash_screen.dart';
import 'package:drive_tracker/features/dashboard/presentation/dashboard_screen.dart';
import 'package:drive_tracker/features/history/presentation/history_screen.dart';
import 'package:drive_tracker/features/settings/presentation/settings_screen.dart';
import 'package:drive_tracker/features/history/presentation/ride_details_screen.dart';
import 'package:drive_tracker/navigation_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _dashboardBranchKey = GlobalKey<NavigatorState>(debugLabel: 'dashboardBranch');
final GlobalKey<NavigatorState> _historyBranchKey = GlobalKey<NavigatorState>(debugLabel: 'historyBranch');
final GlobalKey<NavigatorState> _settingsBranchKey = GlobalKey<NavigatorState>(debugLabel: 'settingsBranch');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  debugLogDiagnostics: true,
  routes: <RouteBase>[
    GoRoute(
      path: '/splash',
      builder: (BuildContext context, GoRouterState state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/ride-details/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) {
        final idStr = state.pathParameters['id'] ?? '';
        final id = int.tryParse(idStr) ?? 0;
        return RideDetailsScreen(driveId: id);
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) {
        return NavigationShell(navigationShell: navigationShell);
      },
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          navigatorKey: _dashboardBranchKey,
          routes: <RouteBase>[
            GoRoute(
              path: '/dashboard',
              builder: (BuildContext context, GoRouterState state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _historyBranchKey,
          routes: <RouteBase>[
            GoRoute(
              path: '/history',
              builder: (BuildContext context, GoRouterState state) => const HistoryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _settingsBranchKey,
          routes: <RouteBase>[
            GoRoute(
              path: '/settings',
              builder: (BuildContext context, GoRouterState state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
