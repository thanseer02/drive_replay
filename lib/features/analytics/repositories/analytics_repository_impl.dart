import 'package:drift/drift.dart';
import 'package:drive_replay/core/services/local_db/app_database.dart';
import 'package:drive_replay/features/analytics/repositories/analytics_repository.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AppDatabase _db;

  AnalyticsRepositoryImpl(this._db);

  @override
  Future<AggregateStats> getAggregateStats(int vehicleId, DateTime start, DateTime end) async {
    // 1. Get Trips for distance, duration, and avg speed
    final tripsQuery = _db.select(_db.trips)
      ..where((t) => t.vehicleId.equals(vehicleId))
      ..where((t) => t.startTime.isBetweenValues(start, end))
      ..where((t) => t.isDeleted.equals(false))
      ..where((t) => t.status.equals('Completed'));

    final trips = await tripsQuery.get();
    
    double totalDistance = 0.0;
    int totalDurationMs = 0;
    final List<int> tripIds = [];

    for (var t in trips) {
      totalDistance += t.totalDistance;
      tripIds.add(t.id);
      if (t.endTime != null) {
        totalDurationMs += t.endTime!.difference(t.startTime).inMilliseconds;
      }
    }

    final totalTripDuration = Duration(milliseconds: totalDurationMs);
    final averageSpeed = totalDurationMs > 0 ? (totalDistance / (totalDurationMs / 1000)) : 0.0;

    // 2. Get Max Speed and Idle Time using TripPoints (if trips exist)
    double maxSpeed = 0.0;
    int idlePointsCount = 0;

    if (tripIds.isNotEmpty) {
      // Find max speed
      final speedExp = _db.tripPoints.speed;
      final maxSpeedQuery = _db.selectOnly(_db.tripPoints)
        ..addColumns([speedExp.max()])
        ..where(_db.tripPoints.tripId.isIn(tripIds));
        
      final maxSpeedResult = await maxSpeedQuery.map((row) => row.read(speedExp.max())).getSingleOrNull();
      maxSpeed = maxSpeedResult ?? 0.0;

      // Find idle time (count of points where speed < 1.0 m/s). Assuming 1 point roughly = 1 second of logging.
      final idleQuery = _db.selectOnly(_db.tripPoints)
        ..addColumns([_db.tripPoints.id.count()])
        ..where(_db.tripPoints.tripId.isIn(tripIds))
        ..where(_db.tripPoints.speed.isSmallerThanValue(1.0));
        
      final idleCountResult = await idleQuery.map((row) => row.read(_db.tripPoints.id.count())).getSingleOrNull();
      idlePointsCount = idleCountResult ?? 0;
    }

    // Multiply count by 2 seconds since our foreground task distanceFilter/timeLimit interval is roughly 2s
    final totalIdleTime = Duration(seconds: idlePointsCount * 2);

    return AggregateStats(
      averageSpeed: averageSpeed,
      maxSpeed: maxSpeed,
      totalTripDuration: totalTripDuration,
      totalDistance: totalDistance,
      totalIdleTime: totalIdleTime,
    );
  }

  @override
  Future<List<DistancePerPeriod>> getDistancePerPeriod(int vehicleId, DateTime start, DateTime end, bool groupByMonth) async {
    final tripsQuery = _db.select(_db.trips)
      ..where((t) => t.vehicleId.equals(vehicleId))
      ..where((t) => t.startTime.isBetweenValues(start, end))
      ..where((t) => t.isDeleted.equals(false))
      ..where((t) => t.status.equals('Completed'));

    final trips = await tripsQuery.get();
    
    // Group in Dart since SQLite date string grouping can be complex across platforms
    final Map<DateTime, double> grouped = {};

    for (var t in trips) {
      DateTime key;
      if (groupByMonth) {
        key = DateTime(t.startTime.year, t.startTime.month, 1);
      } else {
        key = DateTime(t.startTime.year, t.startTime.month, t.startTime.day);
      }
      
      grouped[key] = (grouped[key] ?? 0.0) + t.totalDistance;
    }

    final result = grouped.entries
        .map((e) => DistancePerPeriod(period: e.key, distance: e.value))
        .toList();
        
    result.sort((a, b) => a.period.compareTo(b.period));
    return result;
  }
}
