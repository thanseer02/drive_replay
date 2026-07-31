import 'package:permission_handler/permission_handler.dart';

enum AppPermissionState {
  granted,
  denied,
  permanentlyDenied,
  restricted, // e.g. parental controls
  limited, // mostly iOS, but good for completeness
}

extension PermissionStatusMapper on PermissionStatus {
  AppPermissionState toAppState() {
    switch (this) {
      case PermissionStatus.granted:
        return AppPermissionState.granted;
      case PermissionStatus.denied:
        return AppPermissionState.denied;
      case PermissionStatus.permanentlyDenied:
        return AppPermissionState.permanentlyDenied;
      case PermissionStatus.restricted:
        return AppPermissionState.restricted;
      case PermissionStatus.limited:
        return AppPermissionState.limited;
      case PermissionStatus.provisional:
        return AppPermissionState.granted; // Android 13+ provisional notifications
    }
  }
}
