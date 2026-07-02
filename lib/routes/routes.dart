import 'package:flutter/material.dart';
import '../features/auth/view/splash_screen.dart';
import '../features/auth/view/onboarding_screen.dart';
import '../features/dashboard/view/dashboard_screen.dart';
import '../features/trip_recording/view/live_drive_screen.dart';
import '../features/history/view/history_screen.dart';
import '../features/settings/view/settings_screen.dart';

class AppRouter {
  AppRouter._();

  static Map<String, WidgetBuilder> get routes => {
        SplashScreen.routeName: (context) => const SplashScreen(),
        OnboardingScreen.routeName: (context) => const OnboardingScreen(),
        DashboardScreen.routeName: (context) => const DashboardScreen(),
        LiveDriveScreen.routeName: (context) => const LiveDriveScreen(),
        HistoryScreen.routeName: (context) => const HistoryScreen(),
        SettingsScreen.routeName: (context) => const SettingsScreen(),
      };
}
