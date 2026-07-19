import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drive_tracker/core/di.dart';
import 'package:drive_tracker/database/db_helper.dart';
import 'package:drive_tracker/repositories/ride_repository.dart';
import 'package:drive_tracker/repositories/ride_repository_impl.dart';
import 'package:drive_tracker/services/permission_service.dart';
import 'package:drive_tracker/services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Initialize SharedPreferences & StorageService
    if (!ServiceLocator.isRegistered<StorageService>()) {
      final prefs = await SharedPreferences.getInstance();
      final storageService = StorageService(prefs);
      ServiceLocator.register<StorageService>(storageService);
    }

    // 2. Initialize Core Database Helper & Repositories
    if (!ServiceLocator.isRegistered<RideRepository>()) {
      final dbHelper = DBHelper.instance;
      // Call database getter to trigger initialization
      await dbHelper.database;
      final rideRepository = RideRepositoryImpl(dbHelper);
      ServiceLocator.register<RideRepository>(rideRepository);
    }

    // 3. Register standard services
    if (!ServiceLocator.isRegistered<PermissionService>()) {
      ServiceLocator.register<PermissionService>(PermissionService());
    }

    // Artificial delay to ensure minimum splash time for micro-animations
    await Future.delayed(const Duration(milliseconds: 2000));

    if (mounted) {
      context.go('/dashboard');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.brightness == Brightness.light
                ? [const Color(0xFFEEF2F6), const Color(0xFFFFFFFF)]
                : [const Color(0xFF0B0F19), const Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    // Modern Premium Icon setup
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.2),
                            blurRadius: 30,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Icon(
                        Icons.directions_car_filled_rounded,
                        size: 80,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Drive Tracker',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your smart commuting companion',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: 60,
                height: 60,
                child: Lottie.asset(
                  'assets/lottie/car_loading.json',
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) {
                    return CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    );
                  },
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
