import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'config/app_config.dart';
import 'routes/routes.dart';
import 'utils/colors.dart';

import 'features/auth/view_model/auth_viewmodel.dart';
import 'features/trip_recording/view_model/trip_viewmodel.dart';
import 'features/history/view_model/history_viewmodel.dart';
import 'features/trip_recording/model/trip_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
        return MaterialApp.router(
          title: AppConfig.appName,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Brightness.dark,
              // ignore: deprecated_member_use
              background: AppColors.background,
              surface: AppColors.surface,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.background,
          ),
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
