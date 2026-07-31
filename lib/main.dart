import 'dart:async';
import 'package:flutter/material.dart';
import 'package:drive_replay/core/theme/app_theme.dart';
import 'package:drive_replay/bootstrap/splash_screen.dart';
import 'package:drive_replay/bootstrap/global_error_handler.dart';
import 'package:drive_replay/bootstrap/app_lifecycle_observer.dart';
import 'package:drive_replay/core/logger/logger_service.dart';
import 'package:provider/provider.dart';
import 'package:drive_replay/core/di/dependency_injection.dart';
import 'package:drive_replay/core/permissions/viewmodels/permission_viewmodel.dart';
import 'package:drive_replay/features/dashboard/views/dashboard_screen.dart';

void main() {
  // Catch initialization errors gracefully
  runZonedGuarded(() {
    // 1. Error Handling Init
    GlobalErrorHandler.initialize();

    // 2. Launch the framework
    runApp(const DriveReplayApp());
    
  }, (error, stackTrace) {
    LoggerService.critical('Uncaught Zone Error: $error', error, stackTrace);
  });
}

class DriveReplayApp extends StatefulWidget {
  const DriveReplayApp({super.key});

  @override
  State<DriveReplayApp> createState() => _DriveReplayAppState();
}

class _DriveReplayAppState extends State<DriveReplayApp> {
  late final AppLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = AppLifecycleObserver();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => locator<PermissionViewModel>()),
      ],
      child: MaterialApp(
        title: 'Drive Replay',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(
          nextScreen: DashboardScreen(),
        ),
      ),
    );
  }
}
