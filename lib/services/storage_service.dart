import 'package:shared_preferences/shared_preferences.dart';
import 'package:drive_tracker/core/constants.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Dark Mode Persistence
  bool getDarkMode() {
    return _prefs.getBool(AppConstants.keyDarkMode) ?? false;
  }

  Future<bool> setDarkMode(bool value) async {
    return await _prefs.setBool(AppConstants.keyDarkMode, value);
  }

  // Metric Units Persistence (km vs miles)
  bool getUseMetric() {
    return _prefs.getBool(AppConstants.keyUseMetric) ?? true; // Default to metric
  }

  Future<bool> setUseMetric(bool value) async {
    return await _prefs.setBool(AppConstants.keyUseMetric, value);
  }
}
