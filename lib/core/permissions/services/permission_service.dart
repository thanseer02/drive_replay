import 'package:auto_start_flutter/auto_start_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:drive_replay/core/permissions/models/permission_state.dart';
import 'package:drive_replay/core/logger/logger_service.dart';

class PermissionService {
  /// Check current status without requesting
  Future<AppPermissionState> checkPermission(Permission permission) async {
    final status = await permission.status;
    return status.toAppState();
  }

  /// Request a specific permission
  Future<AppPermissionState> requestPermission(Permission permission) async {
    LoggerService.info('Requesting permission: $permission');
    final status = await permission.request();
    
    // Automatically intercept 'deniedForever' for UX improvement
    if (status.isPermanentlyDenied) {
      LoggerService.warning('Permission $permission permanently denied. User must use OS settings.');
      // The ViewModel will handle prompting the user to open settings.
    }
    
    LoggerService.info('Permission result: $status');
    return status.toAppState();
  }

  /// Special case for Android Background Location (API 30+)
  /// Must be requested only AFTER fine location is granted.
  Future<AppPermissionState> requestBackgroundLocation() async {
    LoggerService.info('Requesting Background Location');
    final status = await Permission.locationAlways.request();
    if (status.isPermanentlyDenied) {
      LoggerService.warning('Background Location permanently denied. User must use OS settings.');
    }
    return status.toAppState();
  }

  /// Check if we need to show a custom rationale (Android 11+)
  Future<bool> shouldShowRequestRationale(Permission permission) async {
    return await permission.shouldShowRequestRationale;
  }

  /// Open OS settings if permission is permanently denied
  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Comprehensive check for all vital permissions
  Future<Map<Permission, AppPermissionState>> checkAllVitals() async {
    return {
      Permission.location: (await Permission.location.status).toAppState(),
      Permission.locationAlways: (await Permission.locationAlways.status).toAppState(),
      Permission.activityRecognition: (await Permission.activityRecognition.status).toAppState(),
      Permission.notification: (await Permission.notification.status).toAppState(),
      Permission.ignoreBatteryOptimizations: (await Permission.ignoreBatteryOptimizations.status).toAppState(),
    };
  }

  /// Handle OEM specific battery restrictions (Xiaomi, Huawei, etc.)
  Future<void> requestOemBackgroundExecution() async {
    try {
      final isAvailable = await isAutoStartAvailable;
      if (isAvailable == true) {
        LoggerService.info('OEM AutoStart detected. Prompting user to whitelist app.');
        await getAutoStartPermission();
      } else {
        LoggerService.info('OEM AutoStart not applicable on this device.');
      }
    } catch (e) {
      LoggerService.error('Failed to check OEM AutoStart: $e');
    }
  }
}
