import 'package:go_router/go_router.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/view/splash_screen.dart';
import '../features/auth/view/onboarding_screen.dart';
import '../features/auth/view/login_screen.dart';
import '../features/dashboard/view/dashboard_screen.dart';
import '../features/trip_recording/view/live_drive_screen.dart';
import '../features/history/view/history_screen.dart';
import '../features/settings/view/settings_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: SplashScreen.routeName,
    routes: [
      GoRoute(
        path: SplashScreen.routeName,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: OnboardingScreen.routeName,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: LoginScreen.routeName,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: DashboardScreen.routeName,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: LiveDriveScreen.routeName,
        name: 'live_drive',
        builder: (context, state) => const LiveDriveScreen(),
      ),
      GoRoute(
        path: HistoryScreen.routeName,
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: SettingsScreen.routeName,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
