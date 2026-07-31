import 'package:drive_replay/core/services/local_db/app_database.dart';

abstract class AnalyticsRepository {
  Future<DrivingScoreData> calculateAndSaveScore(int tripId);
  Future<DrivingScoreData?> getScoreForTrip(int tripId);
}
