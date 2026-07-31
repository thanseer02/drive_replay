import 'package:drift/drift.dart';
import 'package:drive_replay/core/domain/repositories/settings_repository.dart';
import 'package:drive_replay/core/services/local_db/app_database.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final AppDatabase _db;

  SettingsRepositoryImpl(this._db);

  @override
  Future<AppSettings> getSettings() async {
    final query = _db.select(_db.settings)..limit(1);
    final results = await query.get();
    if (results.isEmpty) {
      const defaultSettings = AppSettings(id: 1, themeMode: 'dark', measurementUnit: 'metric', autoRecord: false);
      await _db.into(_db.settings).insert(defaultSettings);
      return defaultSettings;
    }
    return results.first;
  }

  @override
  Future<void> updateTheme(String themeMode) async {
    await (_db.update(_db.settings)..where((t) => t.id.equals(1))).write(
      SettingsCompanion(themeMode: Value(themeMode)),
    );
  }

  @override
  Future<void> updateMeasurementUnit(String unit) async {
    await (_db.update(_db.settings)..where((t) => t.id.equals(1))).write(
      SettingsCompanion(measurementUnit: Value(unit)),
    );
  }
}
