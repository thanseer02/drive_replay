class AggregateStats {
  final double averageSpeed;
  final double maxSpeed;
  final Duration totalTripDuration;
  final double totalDistance;
  final Duration totalIdleTime;

  AggregateStats({
    required this.averageSpeed,
    required this.maxSpeed,
    required this.totalTripDuration,
    required this.totalDistance,
    required this.totalIdleTime,
  });
}

class DistancePerPeriod {
  final DateTime period; // e.g. start of day or month
  final double distance;

  DistancePerPeriod({required this.period, required this.distance});
}

abstract class AnalyticsRepository {
  Future<AggregateStats> getAggregateStats(int vehicleId, DateTime start, DateTime end);
  Future<List<DistancePerPeriod>> getDistancePerPeriod(int vehicleId, DateTime start, DateTime end, bool groupByMonth);
}
