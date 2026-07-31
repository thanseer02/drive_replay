import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drive_replay/core/di/dependency_injection.dart';
import 'package:drive_replay/core/errors/error_handler.dart';
import 'package:drive_replay/core/theme/app_theme.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      ErrorHandler.handleError(details.exception, details.stack);
    };
    
    ErrorWidget.builder = (FlutterErrorDetails details) => ErrorHandler.buildErrorWidget(details);

    // Setup Dependency Injection
    setupLocator();

    runApp(const DriveReplayApp());
  }, (error, stackTrace) {
    // Catch unhandled asynchronous errors
    ErrorHandler.handleError(error, stackTrace);
  });
}

class DriveReplayApp extends StatelessWidget {
  const DriveReplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Example: ChangeNotifierProvider(create: (_) => locator<SomeViewModel>()),
        // We will add providers here as ViewModels are created.
        Provider.value(value: 'Placeholder'), // To prevent empty provider list error if used
      ],
      child: MaterialApp(
        title: 'Drive Replay',
        theme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark, // Enforce dark mode only
        home: const Scaffold(
          body: Center(
            child: Text('Drive Replay Initialized'),
          ),
        ),
      ),
    );
  }
}
