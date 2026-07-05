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
        return MaterialApp(
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
          initialRoute: SplashScreen.routeName,
          routes: AppRouter.routes,
        );
      },
    );
  }
}
