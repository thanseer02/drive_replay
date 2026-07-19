class Drive {
  final int? id;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final double distance; // Always stored in base units (e.g. km) or unit-agnostic
  final String startLocation;
  final String endLocation;
  final String notes;

  Drive({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.distance,
    required this.startLocation,
    required this.endLocation,
    required this.notes,
  });

  Duration get duration => Duration(seconds: durationSeconds);

  // Convert to Map for SQL database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_seconds': durationSeconds,
      'distance': distance,
      'start_location': startLocation,
      'end_location': endLocation,
      'notes': notes,
    };
  }

  // Create from Map from SQL database
  factory Drive.fromMap(Map<String, dynamic> map) {
    return Drive(
      id: map['id'] as int?,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      durationSeconds: map['duration_seconds'] as int,
      distance: (map['distance'] as num).toDouble(),
      startLocation: map['start_location'] as String? ?? '',
      endLocation: map['end_location'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
    );
  }

  Drive copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    double? distance,
    String? startLocation,
    String? endLocation,
    String? notes,
  }) {
    return Drive(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distance: distance ?? this.distance,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      notes: notes ?? this.notes,
    );
  }
}
