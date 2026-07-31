import 'package:get_it/get_it.dart';
import 'package:drive_replay/core/services/local_db/app_database.dart';
import 'package:drive_replay/features/trip_record/repositories/trip_repository.dart';
import 'package:drive_replay/features/history/repositories/trip_repository_impl.dart';
import 'package:drive_replay/core/permissions/services/permission_service.dart';
import 'package:drive_replay/core/permissions/viewmodels/permission_viewmodel.dart';
import 'package:drive_replay/features/trip_record/viewmodels/trip_record_viewmodel.dart';
import 'package:drive_replay/features/history/viewmodels/trip_history_viewmodel.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  // Services
  locator.registerLazySingleton<AppDatabase>(() => AppDatabase());
  locator.registerLazySingleton<PermissionService>(() => PermissionService());
  
  // Repositories
  locator.registerLazySingleton<TripRepository>(() => TripRepositoryImpl(locator<AppDatabase>()));
  
  // ViewModels
  locator.registerLazySingleton<PermissionViewModel>(() => PermissionViewModel(locator<PermissionService>()));
  locator.registerLazySingleton<TripRecordViewModel>(() => TripRecordViewModel());
  locator.registerLazySingleton<TripHistoryViewModel>(() => TripHistoryViewModel(locator<TripRepository>()));
}
