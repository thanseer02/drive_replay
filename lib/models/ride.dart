import 'package:drive_tracker/models/ride_location.dart';

class Ride {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final double maxSpeed;
  final double averageSpeed;
  final double distance;
  final int drivingTime; // in seconds
  final int stopTime; // in seconds
  final DateTime createdAt;
  final List<RideLocation>? locations;

  Ride({
    this.id,
    required this.startTime,
    this.endTime,
    required this.maxSpeed,
    required this.averageSpeed,
    required this.distance,
    required this.drivingTime,
    required this.stopTime,
    required this.createdAt,
    this.locations,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'maxSpeed': maxSpeed,
      'averageSpeed': averageSpeed,
      'distance': distance,
      'drivingTime': drivingTime,
      'stopTime': stopTime,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Duration get duration => Duration(seconds: drivingTime + stopTime);
  int get durationSeconds => drivingTime + stopTime;
  String get notes => 'Logged ride: ${averageSpeed.toStringAsFixed(1)} avg speed, ${maxSpeed.toStringAsFixed(1)} max speed.';
  String get startLocation => 'Drive Start';
  String get endLocation => 'Drive End';

  factory Ride.fromMap(Map<String, dynamic> map, {List<RideLocation>? locations}) {
    return Ride(
      id: map['id'] as int?,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime'] as String) : null,
      maxSpeed: (map['maxSpeed'] as num).toDouble(),
      averageSpeed: (map['averageSpeed'] as num).toDouble(),
      distance: (map['distance'] as num).toDouble(),
      drivingTime: map['drivingTime'] as int,
      stopTime: map['stopTime'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      locations: locations,
    );
  }

  Ride copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    double? maxSpeed,
    double? averageSpeed,
    double? distance,
    int? drivingTime,
    int? stopTime,
    DateTime? createdAt,
    List<RideLocation>? locations,
  }) {
    return Ride(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      distance: distance ?? this.distance,
      drivingTime: drivingTime ?? this.drivingTime,
      stopTime: stopTime ?? this.stopTime,
      createdAt: createdAt ?? this.createdAt,
      locations: locations ?? this.locations,
    );
  }
}
