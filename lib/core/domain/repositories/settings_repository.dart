import 'package:drive_replay/core/services/local_db/app_database.dart';

abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> updateTheme(String themeMode);
  Future<void> updateMeasurementUnit(String unit);
}
