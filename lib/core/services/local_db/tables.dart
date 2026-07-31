import 'package:drift/drift.dart';

@DataClassName('Vehicle')
class Vehicles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get make => text().nullable()();
  TextColumn get model => text().nullable()();
  IntColumn get year => integer().nullable()();
  RealColumn get odometer => real().withDefault(const Constant(0.0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

@DataClassName('AppSettings')
class Settings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get themeMode => text().withDefault(const Constant('dark'))();
  TextColumn get measurementUnit => text().withDefault(const Constant('metric'))();
  BoolColumn get autoRecord => boolean().withDefault(const Constant(false))();
}

@DataClassName('Trip')
class Trips extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vehicleId => integer().references(Vehicles, #id)();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  TextColumn get startLocation => text().nullable()();
  TextColumn get endLocation => text().nullable()();
  RealColumn get totalDistance => real().withDefault(const Constant(0.0))();
  TextColumn get status => text().withDefault(const Constant('Recording'))();
}

@DataClassName('TripPoint')
class TripPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tripId => integer().references(Trips, #id)();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get altitude => real().nullable()();
  RealColumn get heading => real().nullable()();
  RealColumn get accuracy => real().nullable()();
}

@DataClassName('Stop')
class Stops extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tripId => integer().references(Trips, #id)();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
}

@DataClassName('Event')
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tripId => integer().references(Trips, #id)();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get eventType => text()(); // Hard Braking, Rapid Acceleration, Speeding
  TextColumn get severity => text()(); // Low, Medium, High
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
}

@DataClassName('FuelLog')
class FuelLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vehicleId => integer().references(Vehicles, #id)();
  DateTimeColumn get date => dateTime()();
  RealColumn get odometer => real()();
  RealColumn get volume => real()();
  RealColumn get cost => real()();
  BoolColumn get isFullTank => boolean().withDefault(const Constant(true))();
}

@DataClassName('DrivingScoreData')
class DrivingScore extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tripId => integer().references(Trips, #id)();
  RealColumn get score => real()();
  RealColumn get safetyRating => real()();
  RealColumn get efficiencyRating => real()();
  DateTimeColumn get calculatedAt => dateTime()();
}

@DataClassName('SpeedSample')
class SpeedSamples extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tripId => integer().references(Trips, #id)();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get speed => real()();
}

@DataClassName('AccelerationSample')
class AccelerationSamples extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tripId => integer().references(Trips, #id)();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get x => real()();
  RealColumn get y => real()();
  RealColumn get z => real()();
}

@DataClassName('SensorLog')
class SensorLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tripId => integer().references(Trips, #id)();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get gyroX => real()();
  RealColumn get gyroY => real()();
  RealColumn get gyroZ => real()();
  RealColumn get magnetometer => real().nullable()();
}
