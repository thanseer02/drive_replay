import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'trip_model.g.dart';

@HiveType(typeId: 0)
class TripModel extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final DateTime startTime;
  
  @HiveField(2)
  final DateTime? endTime;
  
  @HiveField(3)
  final double distanceInMeters;
  
  @HiveField(4)
  final double topSpeed;
  
  @HiveField(5)
  final double averageSpeed;
  
  @HiveField(6)
  final int score;

  @HiveField(7)
  final List<String> routePath;

  const TripModel({
    required this.id,
    required this.startTime,
    this.endTime,
    this.distanceInMeters = 0.0,
    this.topSpeed = 0.0,
    this.averageSpeed = 0.0,
    this.score = 100, // Starts with a perfect 100 score
    this.routePath = const [],
  });

  TripModel copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    double? distanceInMeters,
    double? topSpeed,
    double? averageSpeed,
    int? score,
    List<String>? routePath,
  }) {
    return TripModel(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distanceInMeters: distanceInMeters ?? this.distanceInMeters,
      topSpeed: topSpeed ?? this.topSpeed,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      score: score ?? this.score,
      routePath: routePath ?? this.routePath,
    );
  }

  @override
  List<Object?> get props => [
        id,
        startTime,
        endTime,
        distanceInMeters,
        topSpeed,
        averageSpeed,
        score,
        routePath,
      ];
}
