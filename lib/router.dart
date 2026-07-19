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
  debugLogDiagnostics: false,
  routes: <RouteBase>[
    GoRoute(
      path: '/splash',
      pageBuilder: (BuildContext context, GoRouterState state) => buildCustomTransitionPage(
        const SplashScreen(),
        state,
      ),
    ),
    GoRoute(
      path: '/ride-details/:id',
      parentNavigatorKey: _rootNavigatorKey,
      // Custom fade+slide transition for the ride details modal
      pageBuilder: (BuildContext context, GoRouterState state) {
        final idStr = state.pathParameters['id'] ?? '';
        final id = int.tryParse(idStr) ?? 0;
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: RideDetailsScreen(driveId: id),
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Bottom-up slide + fade transition (like a modal sheet)
            final slideAnim = Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: slideAnim, child: child),
            );
          },
        );
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
              pageBuilder: (BuildContext context, GoRouterState state) => buildCustomTransitionPage(
                const DashboardScreen(),
                state,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _historyBranchKey,
          routes: <RouteBase>[
            GoRoute(
              path: '/history',
              pageBuilder: (BuildContext context, GoRouterState state) => buildCustomTransitionPage(
                const HistoryScreen(),
                state,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _settingsBranchKey,
          routes: <RouteBase>[
            GoRoute(
              path: '/settings',
              pageBuilder: (BuildContext context, GoRouterState state) => buildCustomTransitionPage(
                const SettingsScreen(),
                state,
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

CustomTransitionPage<void> buildCustomTransitionPage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
  );
}

