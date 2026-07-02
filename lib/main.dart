import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'config/app_config.dart';
import 'routes/routes.dart';
import 'utils/colors.dart';

import 'features/auth/view_model/auth_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter(AppConfig.dbName);
  
  // TODO: Register Hive Adapters here
  // TODO: Open Hive Boxes here

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
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
