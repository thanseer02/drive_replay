import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  PermissionHelper._();

  /// Requests location permissions, including background location which is vital for a dashcam.
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      // Request background location for continuous recording
      final bgStatus = await Permission.locationAlways.request();
      return bgStatus.isGranted || status.isGranted;
    }
    return false;
  }

  /// Requests camera permission for dashcam recording.
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Requests storage permission for saving recorded videos and logs.
  static Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    // On newer Android versions, we might need manageExternalStorage or photos/videos permissions
    return status.isGranted;
  }

  /// Checks if location services are globally enabled on the device.
  static Future<bool> isLocationServicesEnabled() async {
    return await Permission.location.serviceStatus.isEnabled;
  }
}
