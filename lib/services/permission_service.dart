import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class PermissionService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Helper to fetch Android SDK level
  Future<int> _getAndroidSdk() async {
    if (!Platform.isAndroid) return 0;
    final androidInfo = await _deviceInfo.androidInfo;
    return androidInfo.version.sdkInt;
  }

  // ==========================================
  // LOCATION PERMISSIONS
  // ==========================================

  // Check foreground location permission
  Future<PermissionStatus> checkLocationPermission() async {
    return await Permission.locationWhenInUse.status;
  }

  // Request foreground location permission
  Future<PermissionStatus> requestLocationPermission() async {
    return await Permission.locationWhenInUse.request();
  }

  // Check background location permission
  Future<PermissionStatus> checkBackgroundLocationPermission() async {
    return await Permission.locationAlways.status;
  }

  // Request background location permission
  Future<PermissionStatus> requestBackgroundLocationPermission() async {
    return await Permission.locationAlways.request();
  }

  // ==========================================
  // NOTIFICATION PERMISSIONS
  // ==========================================

  // Check notification permission
  Future<PermissionStatus> checkNotificationPermission() async {
    return await Permission.notification.status;
  }

  // Request notification permission
  Future<PermissionStatus> requestNotificationPermission() async {
    final sdk = await _getAndroidSdk();
    if (sdk >= 33) {
      return await Permission.notification.request();
    }
    return PermissionStatus.granted;
  }

  // ==========================================
  // BATTERY OPTIMIZATION PERMISSIONS
  // ==========================================

  // Check if battery optimizations are ignored (i.e. App is whitelisted)
  Future<PermissionStatus> checkBatteryOptimizationPermission() async {
    return await Permission.ignoreBatteryOptimizations.status;
  }

  // Request ignoring battery optimizations
  Future<PermissionStatus> requestBatteryOptimizationPermission() async {
    return await Permission.ignoreBatteryOptimizations.request();
  }

  // ==========================================
  // EXACT ALARM PERMISSIONS
  // ==========================================

  // Check exact alarm permission
  Future<PermissionStatus> checkExactAlarmPermission() async {
    final sdk = await _getAndroidSdk();
    if (sdk >= 31) {
      return await Permission.scheduleExactAlarm.status;
    }
    return PermissionStatus.granted;
  }

  // Request exact alarm permission
  Future<PermissionStatus> requestExactAlarmPermission() async {
    final sdk = await _getAndroidSdk();
    if (sdk >= 31) {
      return await Permission.scheduleExactAlarm.request();
    }
    return PermissionStatus.granted;
  }

  // ==========================================
  // MASTER CHECKS
  // ==========================================

  // Verify all mandatory operational permissions
  Future<bool> hasMandatoryPermissions() async {
    final locationStatus = await checkLocationPermission();
    if (!locationStatus.isGranted) return false;

    final sdk = await _getAndroidSdk();
    if (sdk >= 33) {
      final notifStatus = await checkNotificationPermission();
      if (!notifStatus.isGranted) return false;
    }

    return true;
  }

  // Check if open settings redirection is needed
  void openAppSettingsPage() {
    openAppSettings();
  }
}
