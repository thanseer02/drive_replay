import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Check location permission state
  Future<PermissionStatus> checkLocationPermission() async {
    return await Permission.locationWhenInUse.status;
  }

  // Request location permission
  Future<PermissionStatus> requestLocationPermission() async {
    return await Permission.locationWhenInUse.request();
  }

  // Check if location permission is granted
  Future<bool> isLocationGranted() async {
    final status = await checkLocationPermission();
    return status.isGranted;
  }
}
