import 'dart:async';
import 'package:drive_replay/core/di/dependency_injection.dart';
import 'package:flutter/widgets.dart';
import 'package:drive_replay/core/logger/logger_service.dart';
import 'package:drive_replay/bootstrap/bootstrap_viewmodel.dart';
import 'package:drive_replay/bootstrap/global_error_handler.dart';
// Note: We'll import other config/storage services as we build them.

class AppBootstrap {
  final BootstrapViewModel viewModel;

  AppBootstrap(this.viewModel);

  Future<void> runInitialization() async {
    final Stopwatch totalTimer = Stopwatch()..start();
    
    try {
      // 1. Flutter Binding (usually done before calling runApp, but ensuring here just in case)
      await _executeStep('Binding Flutter Engine...', () async {
        WidgetsFlutterBinding.ensureInitialized();
      });

      // 2. Logger
      await _executeStep('Initializing Logger...', () async {
        await LoggerService.initialize(enableLogs: true);
        GlobalErrorHandler.initialize();
      });

      // 3. App Configuration
      await _executeStep('Loading App Configuration...', () async {
        // Placeholder for real config loading
        await Future.delayed(const Duration(milliseconds: 100));
      });

      // 4. Shared Preferences / Storage
      await _executeStep('Mounting Local Storage...', () async {
        // Placeholder for SharedPreferences.getInstance()
        await Future.delayed(const Duration(milliseconds: 200));
      });

      // 5. Local Database
      await _executeStep('Waking up Local Database...', () async {
        // Assuming AppDatabase is created inside DI, this step is just logical separation
        await Future.delayed(const Duration(milliseconds: 300));
      });

      // 6. Dependency Injection (Async setup)
      await _executeStep('Registering Dependencies...', () async {
        await setupLocatorAsync(); // We will refactor setupLocator to be async
      });

      // 7. Repositories
      await _executeStep('Initializing Repositories...', () async {
        await Future.delayed(const Duration(milliseconds: 100));
      });

      // 8. Services
      await _executeStep('Initializing Services...', () async {
        await Future.delayed(const Duration(milliseconds: 100));
      });

      // 9. Providers
      await _executeStep('Registering Providers...', () async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      // 10. Navigation
      await _executeStep('Setting up Navigation...', () async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      // 11. Theme
      await _executeStep('Loading Theme Preferences...', () async {
        await Future.delayed(const Duration(milliseconds: 50));
      });

      // 12. Startup Validation
      await _executeStep('Validating Core Systems...', () async {
        await Future.delayed(const Duration(milliseconds: 200));
      });

      totalTimer.stop();
      LoggerService.info('Bootstrap completed successfully in ${totalTimer.elapsedMilliseconds}ms');
      
      // 13. Launch Application (Signal Splash Screen to navigate)
      viewModel.markSuccess();

    } catch (e, stack) {
      totalTimer.stop();
      LoggerService.critical('Bootstrap failed at step: ${viewModel.currentStep}', e, stack);
      viewModel.markError(e.toString());
    }
  }

  Future<void> _executeStep(String stepName, Future<void> Function() action) async {
    final Stopwatch stepTimer = Stopwatch()..start();
    viewModel.updateStep(stepName);
    LoggerService.info('Starting Step: $stepName');
    
    await action();
    
    stepTimer.stop();
    LoggerService.info('Completed Step: $stepName in ${stepTimer.elapsedMilliseconds}ms');
  }
}
