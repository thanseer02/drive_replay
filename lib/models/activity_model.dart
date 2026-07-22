import 'package:drive_tracker/models/activity_location.dart';

class ActivityModel {
  final int? id;
  final String activityType;
  final DateTime startTime;
  final DateTime? endTime;
  final double maxSpeed;
  final double averageSpeed;
  final double distance;
  final int duration;
  final int stopTime;
  final int steps;
  final double calories;
  final double pace;
  final double cadence;
  final DateTime createdAt;
  final List<ActivityLocation>? locations;

  ActivityModel({
    this.id,
    required this.activityType,
    required this.startTime,
    this.endTime,
    required this.maxSpeed,
    required this.averageSpeed,
    required this.distance,
    required this.duration,
    required this.stopTime,
    this.steps = 0,
    this.calories = 0.0,
    this.pace = 0.0,
    this.cadence = 0.0,
    required this.createdAt,
    this.locations,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activityType': activityType,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'maxSpeed': maxSpeed,
      'averageSpeed': averageSpeed,
      'distance': distance,
      'duration': duration,
      'stopTime': stopTime,
      'steps': steps,
      'calories': calories,
      'pace': pace,
      'cadence': cadence,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map, {List<ActivityLocation>? locations}) {
    return ActivityModel(
      id: map['id'] as int?,
      activityType: map['activityType'] as String? ?? 'driving',
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime'] as String) : null,
      maxSpeed: (map['maxSpeed'] as num).toDouble(),
      averageSpeed: (map['averageSpeed'] as num).toDouble(),
      distance: (map['distance'] as num).toDouble(),
      duration: map['duration'] as int? ?? map['drivingTime'] as int? ?? 0,
      stopTime: map['stopTime'] as int,
      steps: map['steps'] as int? ?? 0,
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      pace: (map['pace'] as num?)?.toDouble() ?? 0.0,
      cadence: (map['cadence'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      locations: locations,
    );
  }
}
