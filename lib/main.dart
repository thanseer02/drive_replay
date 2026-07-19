import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drive_tracker/core/di.dart';
import 'package:drive_tracker/core/theme.dart';
import 'package:drive_tracker/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:drive_tracker/features/history/viewmodel/history_viewmodel.dart';
import 'package:drive_tracker/features/settings/viewmodel/settings_viewmodel.dart';
import 'package:drive_tracker/router.dart';
import 'package:drive_tracker/services/storage_service.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized before running setup
  WidgetsFlutterBinding.ensureInitialized();

  // Create temporary local storage instance pre-load to set initial theme
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  ServiceLocator.register<StorageService>(storageService);

  runApp(
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
  );
}

class DriveTrackerApp extends StatelessWidget {
  const DriveTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to changes in settings viewmodel to update theme dynamically
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
