import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:drive_replay/core/services/local_db/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Vehicles,
  Settings,
  Trips,
  TripPoints,
  Stops,
  Events,
  FuelLogs,
  DrivingScore,
  SpeedSamples,
  AccelerationSamples,
  SensorLogs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        
        // Setup initial default data
        await into(settings).insert(
          const SettingsCompanion(
            themeMode: Value('dark'),
            measurementUnit: Value('metric'),
            autoRecord: Value(false),
          ),
        );
        
        await into(vehicles).insert(
          const VehiclesCompanion(
            name: Value('My Vehicle'),
            make: Value('Unknown'),
            model: Value('Unknown'),
          ),
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1) {
          // We forgot to seed vehicle 1 in schema 1. 
          // Insert it now if it doesn't exist.
          await customStatement("INSERT OR IGNORE INTO vehicles (id, name, is_active, odometer) VALUES (1, 'My Vehicle', 1, 0.0);");
        }
      },
      beforeOpen: (details) async {
        // Ensure foreign keys are strictly enforced
        await customStatement('PRAGMA foreign_keys = ON;');
        
        // Trip Integrity Checker: Auto-close any "Recording" trips older than 12 hours
        // This prevents orphaned active trips if the isolate crashed and failed to recover.
        final cutoffTime = DateTime.now().subtract(const Duration(hours: 12));
        final cutoffSeconds = cutoffTime.millisecondsSinceEpoch ~/ 1000;
        await customStatement(
          "UPDATE trips SET status = 'Finished' WHERE status = 'Recording' AND strftime('%s', start_time) < '$cutoffSeconds'"
        );
        
        // Create indexes for fast lookup (can also be defined via custom statement if complex)
        await customStatement('CREATE INDEX IF NOT EXISTS idx_trip_points_trip_time ON trip_points (trip_id, timestamp);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_speed_trip_time ON speed_samples (trip_id, timestamp);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_accel_trip_time ON acceleration_samples (trip_id, timestamp);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_events_trip ON events (trip_id);');
        await customStatement('CREATE INDEX IF NOT EXISTS idx_trips_vehicle_time ON trips (vehicle_id, start_time);');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'drive_replay.sqlite'));



    return NativeDatabase.createInBackground(file);
  });
}
