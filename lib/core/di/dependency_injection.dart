import 'package:get_it/get_it.dart';
import 'package:drive_replay/core/services/local_db/app_database.dart';
import 'package:drive_replay/core/domain/repositories/trip_repository.dart';
import 'package:drive_replay/core/data/repositories/trip_repository_impl.dart';
import 'package:drive_replay/core/permissions/services/permission_service.dart';
import 'package:drive_replay/core/permissions/viewmodels/permission_viewmodel.dart';
import 'package:drive_replay/features/trip_record/viewmodels/trip_record_viewmodel.dart';
import 'package:drive_replay/features/history/viewmodels/trip_history_viewmodel.dart';
import 'package:drive_replay/features/replay/viewmodels/replay_viewmodel.dart';
import 'package:drive_replay/core/domain/repositories/analytics_repository.dart';
import 'package:drive_replay/core/data/repositories/analytics_repository_impl.dart';
import 'package:drive_replay/features/analytics/viewmodels/analytics_viewmodel.dart';
import 'package:drive_replay/features/dashboard/viewmodels/dashboard_viewmodel.dart';

final GetIt locator = GetIt.instance;

Future<void> setupLocatorAsync() async {
  // Services
  locator.registerLazySingleton<AppDatabase>(() => AppDatabase());
  locator.registerLazySingleton<PermissionService>(() => PermissionService());
  
  // Repositories
  locator.registerLazySingleton<TripRepository>(() => TripRepositoryImpl(locator<AppDatabase>()));
  locator.registerLazySingleton<AnalyticsRepository>(() => AnalyticsRepositoryImpl(locator<AppDatabase>()));
  
  // ViewModels
  locator.registerFactory<PermissionViewModel>(() => PermissionViewModel(locator<PermissionService>()));
  locator.registerFactory<TripRecordViewModel>(() => TripRecordViewModel(locator<TripRepository>()));
  locator.registerFactory<TripHistoryViewModel>(() => TripHistoryViewModel(locator<TripRepository>()));
  locator.registerFactory<ReplayViewModel>(() => ReplayViewModel(locator<TripRepository>()));
  locator.registerFactory<AnalyticsViewModel>(() => AnalyticsViewModel(locator<AnalyticsRepository>()));
  locator.registerFactory<DashboardViewModel>(() => DashboardViewModel(locator<TripRepository>()));
}
