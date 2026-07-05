import 'package:firebase_core/firebase_core.dart';
import 'package:drive_replay/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';

import 'features/auth/view/splash_screen.dart';
import 'routes/routes.dart';
import 'utils/colors.dart';

import 'features/auth/view_model/auth_viewmodel.dart';
import 'features/trip_recording/view_model/trip_viewmodel.dart';
import 'features/history/view_model/history_viewmodel.dart';
import 'features/trip_recording/model/trip_model.dart';

// Analytics Imports
import 'package:flutter_background_analyser/features/analytics/core/storage/hive_storage_service.dart';
import 'package:flutter_background_analyser/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:flutter_background_analyser/features/analytics/core/queue/queue_manager.dart';
import 'package:flutter_background_analyser/features/analytics/core/session/session_manager.dart';
import 'package:flutter_background_analyser/features/analytics/core/recorder/device_metadata_service.dart';
import 'package:flutter_background_analyser/features/analytics/presentation/services/analytics.dart';
import 'package:flutter_background_analyser/features/analytics/core/sync/sync_engine.dart';
import 'package:flutter_background_analyser/features/analytics/core/trackers/app_lifecycle_observer.dart';
import 'package:flutter_background_analyser/features/analytics/core/trackers/error_tracker_service.dart';
import 'package:flutter_background_analyser/features/analytics/core/trackers/analytics_gesture_detector.dart';
import 'package:flutter_background_analyser/features/analytics/core/trackers/analytics_navigator_observer.dart';

import 'services/analytics/connectivity_network_repository.dart';
import 'services/analytics/preferences_session_repository.dart';
import 'services/analytics/console_upload_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Lock app to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Hive
  await Hive.initFlutter(AppConfig.dbName);
  
  Hive.registerAdapter(TripModelAdapter());
  await Hive.openBox<TripModel>('trips_box');

  // Initialize Analytics
  final storageService = HiveStorageService();
  await storageService.init();

  final analyticsRepo = AnalyticsRepositoryImpl(storageService);
  final queueManager = QueueManager(analyticsRepo);
  final sessionManager = SessionManager(PreferencesSessionRepository());
  final metadataService = DeviceMetadataService();

  final analytics = Analytics();
  await analytics.initialize(
    queueManager: queueManager,
    sessionManager: sessionManager,
    metadataService: metadataService,
  );

  final syncEngine = SyncEngine(
    queueManager, 
    ConsoleUploadService(), 
    ConnectivityNetworkRepository()
  );
  syncEngine.startSyncTimer(interval: const Duration(minutes: 2));

  final lifecycleObserver = AppLifecycleObserver(analytics);
  lifecycleObserver.start();

  final errorTrackerService = ErrorTrackerService(analytics);
  errorTrackerService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => TripViewModel()),
        ChangeNotifierProvider(create: (_) => HistoryViewModel()),
      ],
      child: const DriveReplayApp(),
    ),
  );
}

class DriveReplayApp extends StatelessWidget {
  const DriveReplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Standard mobile layout
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return AnalyticsGestureDetector(
          tracker: Analytics(),
          child: MaterialApp(
            title: 'Drive Replay',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primaryColor: AppColors.primary,
              scaffoldBackgroundColor: AppColors.background,
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primary,
                secondary: AppColors.primaryLight,
                surface: AppColors.surface,
              ),
              useMaterial3: true,
            ),
            navigatorObservers: [
              AnalyticsNavigatorObserver(Analytics()),
            ],
            initialRoute: SplashScreen.routeName,
            routes: AppRouter.routes,
          ),
        );
      },
    );
  }
}
