import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drive_replay/core/services/local_db/app_database.dart';
import 'package:drive_replay/core/data/repositories/trip_repository_impl.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  late AppDatabase database;
  late TripRepositoryImpl repository;

  setUp(() {
    // In a real test suite, we would construct AppDatabase with NativeDatabase.memory()
    database = AppDatabase();
    repository = TripRepositoryImpl(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('Database is instantiated properly', () {
    expect(database, isNotNull);
  });
}
