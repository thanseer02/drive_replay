import 'package:flutter/material.dart';
import 'package:drive_tracker/core/di.dart';
import 'package:drive_tracker/models/settings_model.dart';
import 'package:drive_tracker/repositories/ride_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  final RideRepository _rideRepository = ServiceLocator.get<RideRepository>();

  bool _isDarkMode = false;
  bool _useMetric = true;
  bool _initialized = false;

  SettingsViewModel() {
    _loadSettings();
  }

  bool get isDarkMode => _isDarkMode;
  bool get useMetric => _useMetric;
  bool get initialized => _initialized;

  Future<void> _loadSettings() async {
    try {
      final settings = await _rideRepository.getSettings();
      _isDarkMode = settings.isDarkMode;
      _useMetric = settings.useMetric;
      _initialized = true;
      notifyListeners();
    } catch (e) {
      // Keep defaults
    }
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    await _rideRepository.updateSettings(
      SettingsModel(isDarkMode: _isDarkMode, useMetric: _useMetric),
    );
  }

  Future<void> toggleUseMetric(bool value) async {
    _useMetric = value;
    notifyListeners();
    await _rideRepository.updateSettings(
      SettingsModel(isDarkMode: _isDarkMode, useMetric: _useMetric),
    );
  }
}
