import 'package:flutter/material.dart';
import 'package:drive_tracker/core/di.dart';
import 'package:drive_tracker/services/storage_service.dart';

class SettingsViewModel extends ChangeNotifier {
  final StorageService _storageService = ServiceLocator.get<StorageService>();

  late bool _isDarkMode;
  late bool _useMetric;

  SettingsViewModel() {
    _isDarkMode = _storageService.getDarkMode();
    _useMetric = _storageService.getUseMetric();
  }

  bool get isDarkMode => _isDarkMode;
  bool get useMetric => _useMetric;

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    await _storageService.setDarkMode(value);
    notifyListeners();
  }

  Future<void> toggleUseMetric(bool value) async {
    _useMetric = value;
    await _storageService.setUseMetric(value);
    notifyListeners();
  }
}
