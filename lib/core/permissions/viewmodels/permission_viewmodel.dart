import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:drive_replay/core/permissions/services/permission_service.dart';
import 'package:drive_replay/core/permissions/models/permission_state.dart';
import 'package:drive_replay/core/logger/app_logger.dart';

class PermissionViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final PermissionService _permissionService;

  Map<Permission, AppPermissionState> _states = {};

  PermissionViewModel(this._permissionService) {
    WidgetsBinding.instance.addObserver(this);
    checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User might have changed permissions in Android Settings
      AppLogger.i('App resumed. Re-checking all permissions.');
      checkAllPermissions();
    }
  }

  AppPermissionState getState(Permission permission) {
    return _states[permission] ?? AppPermissionState.denied;
  }

  bool get isLocationReady {
    // For our app, Fine location is strictly required.
    return getState(Permission.location) == AppPermissionState.granted;
  }

  bool get isBackgroundLocationReady {
    return getState(Permission.locationAlways) == AppPermissionState.granted;
  }

  bool get isBatteryOptimizationIgnored {
    return getState(Permission.ignoreBatteryOptimizations) == AppPermissionState.granted;
  }

  Future<void> checkAllPermissions() async {
    _states = await _permissionService.checkAllVitals();
    notifyListeners();
  }

  Future<void> requestLocation() async {
    final state = await _permissionService.requestPermission(Permission.location);
    _states[Permission.location] = state;
    notifyListeners();
  }

  Future<void> requestBackgroundLocation() async {
    // Must only be called if Fine Location is already granted
    final state = await _permissionService.requestBackgroundLocation();
    _states[Permission.locationAlways] = state;
    notifyListeners();
  }

  Future<void> requestBatteryOptimization() async {
    final state = await _permissionService.requestPermission(Permission.ignoreBatteryOptimizations);
    _states[Permission.ignoreBatteryOptimizations] = state;
    notifyListeners();
  }
  
  Future<void> requestActivityRecognition() async {
    final state = await _permissionService.requestPermission(Permission.activityRecognition);
    _states[Permission.activityRecognition] = state;
    notifyListeners();
  }

  Future<void> requestNotifications() async {
    final state = await _permissionService.requestPermission(Permission.notification);
    _states[Permission.notification] = state;
    notifyListeners();
  }

  Future<void> openSettings() async {
    await _permissionService.openSettings();
  }
}
