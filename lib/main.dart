import 'dart:async';
import 'dart:ui';
import 'package:drive_tracker/themes/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drive_tracker/core/di.dart';
import 'package:drive_tracker/core/theme.dart';
import 'package:drive_tracker/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:drive_tracker/features/history/viewmodel/history_viewmodel.dart';
import 'package:drive_tracker/features/settings/viewmodel/settings_viewmodel.dart';
import 'package:drive_tracker/router.dart';
import 'package:drive_tracker/services/storage_service.dart';
import 'package:drive_tracker/database/db_helper.dart';
import 'package:drive_tracker/repositories/ride_repository.dart';
import 'package:drive_tracker/repositories/ride_repository_impl.dart';
import 'package:drive_tracker/services/permission_service.dart';


// ─── Crash-safe global error boundary ─────────────────────────────────────
void _handleFlutterError(FlutterErrorDetails details) {
  // Log error (would send to Crashlytics/Sentry in production)
  debugPrint('⚠️ Flutter Error: ${details.exceptionAsString()}');
  debugPrint(details.stack.toString());
}

bool _handlePlatformError(Object error, StackTrace stack) {
  debugPrint('⚠️ Platform Error: $error');
  debugPrint(stack.toString());
  return true; // Prevents propagation
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Crash-safe handlers
  FlutterError.onError = _handleFlutterError;
  PlatformDispatcher.instance.onError = _handlePlatformError;

  // Branded error widget for release mode
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const _AppCrashFallback();
  };

  // System UI styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Support all orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  ServiceLocator.register<StorageService>(storageService);

  // Register core services early to prevent race conditions during ViewModel creation
  final dbHelper = DBHelper.instance;
  await dbHelper.database;
  final rideRepository = RideRepositoryImpl(dbHelper);
  ServiceLocator.register<RideRepository>(rideRepository);
  ServiceLocator.register<PermissionService>(PermissionService());


  runZonedGuarded(
    () => runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsViewModel>(
            create: (_) => SettingsViewModel(),
          ),
          ChangeNotifierProvider<DashboardViewModel>(
            create: (_) => DashboardViewModel(),
          ),
          ChangeNotifierProvider<HistoryViewModel>(
            create: (_) => HistoryViewModel(),
          ),
        ],
        child: const DriveTrackerApp(),
      ),
    ),
    (error, stack) {
      debugPrint('⚠️ Zone Error: $error\n$stack');
    },
  );
}

class DriveTrackerApp extends StatelessWidget {
  const DriveTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();

    return MaterialApp.router(
      title: 'Drive Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}

/// ─── Branded crash fallback widget ────────────────────────────────────────
class _AppCrashFallback extends StatelessWidget {
  const _AppCrashFallback();

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, size: 64, color: Color(0xFFF43F5E)),
                SizedBox(height: 24),
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'Please restart the app. If the problem persists, contact support.',
                  style: AppTextStyles.ts15w400.copyWith(color: const Color(0xFF94A3B8)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
