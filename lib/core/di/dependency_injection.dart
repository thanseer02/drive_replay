import 'package:get_it/get_it.dart';
import 'package:drive_replay/core/permissions/services/permission_service.dart';
import 'package:drive_replay/core/permissions/viewmodels/permission_viewmodel.dart';
import 'package:drive_replay/features/trip_record/viewmodels/trip_record_viewmodel.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  // Services
  locator.registerLazySingleton<PermissionService>(() => PermissionService());
  
  // Repositories
  
  // ViewModels
  locator.registerLazySingleton<PermissionViewModel>(() => PermissionViewModel(locator<PermissionService>()));
  locator.registerLazySingleton<TripRecordViewModel>(() => TripRecordViewModel());
}
