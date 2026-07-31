import 'dart:async';
import 'package:flutter/material.dart';
import 'package:drive_replay/core/theme/app_theme.dart';
import 'package:drive_replay/bootstrap/splash_screen.dart';
import 'package:drive_replay/bootstrap/global_error_handler.dart';
import 'package:drive_replay/bootstrap/app_lifecycle_observer.dart';
import 'package:drive_replay/core/logger/logger_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:drive_replay/core/di/dependency_injection.dart';
import 'package:drive_replay/core/permissions/viewmodels/permission_viewmodel.dart';
import 'package:drive_replay/features/settings/viewmodels/settings_viewmodel.dart';
import 'package:drive_replay/features/dashboard/views/dashboard_screen.dart';
import 'package:flutter/services.dart';

void main() {
  // Catch initialization errors gracefully
  runZonedGuarded(() async {
    // 1. Error Handling Init
    GlobalErrorHandler.initialize();

    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // 2. Setup Dependency Injection
    await setupLocatorAsync();

    // 3. Launch the framework
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
        ChangeNotifierProvider(create: (_) => locator<SettingsViewModel>()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(393, 852), // Standard modern phone dimensions
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return Consumer<SettingsViewModel>(
            builder: (context, settingsVm, child) {
              return MaterialApp(
                title: 'Drive Replay',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: settingsVm.flutterThemeMode,
                debugShowCheckedModeBanner: false,
                home: const SplashScreen(
                  nextScreen: DashboardScreen(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
