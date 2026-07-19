class RideLocation {
  final int? id;
  final int rideId;
  final double latitude;
  final double longitude;
  final double speed;
  final double accuracy;
  final DateTime timestamp;

  RideLocation({
    this.id,
    required this.rideId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.accuracy,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rideId': rideId,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory RideLocation.fromMap(Map<String, dynamic> map) {
    return RideLocation(
      id: map['id'] as int?,
      rideId: map['rideId'] as int,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      speed: (map['speed'] as num).toDouble(),
      accuracy: (map['accuracy'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
