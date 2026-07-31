import 'package:flutter/material.dart';
import 'package:drive_replay/core/domain/repositories/settings_repository.dart';
import 'package:drive_replay/core/logger/logger_service.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsRepository _repository;

  bool _isLoading = true;
  String _themeMode = 'dark';
  String _measurementUnit = 'metric';

  SettingsViewModel(this._repository) {
    _initSettings();
  }

  bool get isLoading => _isLoading;
  String get themeMode => _themeMode;
  String get measurementUnit => _measurementUnit;

  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> _initSettings() async {
    try {
      final settings = await _repository.getSettings();
      _themeMode = settings.themeMode;
      _measurementUnit = settings.measurementUnit;
    } catch (e) {
      LoggerService.error('Failed to load settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTheme(String theme) async {
    _themeMode = theme;
    notifyListeners();
    await _repository.updateTheme(theme);
  }

  Future<void> updateMeasurementUnit(String unit) async {
    _measurementUnit = unit;
    notifyListeners();
    await _repository.updateMeasurementUnit(unit);
  }

  // Unit conversion helpers based on m/s
  double convertSpeed(double speedMps) {
    switch (_measurementUnit) {
      case 'imperial':
        return speedMps * 2.23694; // mph
      case 'nautical':
        return speedMps * 1.94384; // knots
      case 'metric':
      default:
        return speedMps * 3.6; // km/h
    }
  }

  String get speedUnitString {
    switch (_measurementUnit) {
      case 'imperial':
        return 'mph';
      case 'nautical':
        return 'knots';
      case 'metric':
      default:
        return 'km/h';
    }
  }

  // Unit conversion for distance (meters)
  double convertDistance(double distanceMeters) {
    switch (_measurementUnit) {
      case 'imperial':
        return distanceMeters / 1609.34; // miles
      case 'nautical':
        return distanceMeters / 1852.0; // nautical miles
      case 'metric':
      default:
        return distanceMeters / 1000.0; // km
    }
  }

  String get distanceUnitString {
    switch (_measurementUnit) {
      case 'imperial':
        return 'mi';
      case 'nautical':
        return 'nm';
      case 'metric':
      default:
        return 'km';
    }
  }
}
