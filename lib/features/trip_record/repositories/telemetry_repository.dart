import 'package:drive_replay/core/services/local_db/app_database.dart';

abstract class TelemetryRepository {
  Future<void> insertTripPoints(List<TripPoint> points);
  Future<void> insertSensorLogs(List<SensorLog> logs);
  Future<void> insertSpeedSamples(List<SpeedSample> samples);
  
  Stream<List<TripPoint>> streamTripPoints(int tripId);
}
