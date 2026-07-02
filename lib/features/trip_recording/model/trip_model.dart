import 'package:equatable/equatable.dart';

class TripModel extends Equatable {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceInMeters;
  final double topSpeed;
  final double averageSpeed;
  final int score;

  const TripModel({
    required this.id,
    required this.startTime,
    this.endTime,
    this.distanceInMeters = 0.0,
    this.topSpeed = 0.0,
    this.averageSpeed = 0.0,
    this.score = 100, // Starts with a perfect 100 score
  });

  TripModel copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    double? distanceInMeters,
    double? topSpeed,
    double? averageSpeed,
    int? score,
  }) {
    return TripModel(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      distanceInMeters: distanceInMeters ?? this.distanceInMeters,
      topSpeed: topSpeed ?? this.topSpeed,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      score: score ?? this.score,
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
      ];
}
