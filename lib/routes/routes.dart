import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/view/splash_screen.dart';
import '../features/auth/view/onboarding_screen.dart';
import '../features/auth/view/login_screen.dart';

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
      // Placeholder for Dashboard
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Dashboard Placeholder')),
        ),
      )
    ],
  );
}
