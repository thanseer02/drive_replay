class ActivityLocation {
  final int? id;
  final int activityId;
  final double latitude;
  final double longitude;
  final double speed;
  final double accuracy;
  final double heading;
  final double altitude;
  final DateTime timestamp;

  ActivityLocation({
    this.id,
    required this.activityId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.accuracy,
    this.heading = 0.0,
    this.altitude = 0.0,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activityId': activityId,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'accuracy': accuracy,
      'heading': heading,
      'altitude': altitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ActivityLocation.fromMap(Map<String, dynamic> map) {
    return ActivityLocation(
      id: map['id'] as int?,
      activityId: map['activityId'] as int? ?? map['rideId'] as int? ?? 0,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      speed: (map['speed'] as num).toDouble(),
      accuracy: (map['accuracy'] as num).toDouble(),
      heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
      altitude: (map['altitude'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
