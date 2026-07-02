import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../utils/colors.dart';
import '../../../utils/styles.dart';
import '../../trip_recording/model/trip_model.dart';

class TripDetailScreen extends StatelessWidget {
  final TripModel trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final distanceKm = (trip.distanceInMeters / 1000).toStringAsFixed(2);
    final topSpeedKmH = (trip.topSpeed * 3.6).toStringAsFixed(1);
    final avgSpeedKmH = (trip.averageSpeed * 3.6).toStringAsFixed(1);

    final startTimeStr = DateFormat(
      'MMM d, yyyy • h:mm a',
    ).format(trip.startTime);
    final durationStr = trip.endTime != null
        ? _formatDuration(trip.endTime!.difference(trip.startTime))
        : 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: Text('Trip Details', style: AppStyles.tsS20W600CFFFFFF),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.spMin),
        children: [
          // Score Card
          Container(
            padding: EdgeInsets.all(24.spMin),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20.spMin),
            ),
            child: Column(
              children: [
                Text('Driving Score', style: AppStyles.tsS16W400CFFFFFF),
                SizedBox(height: 16.spMin),
                Container(
                  width: 100.spMin,
                  height: 100.spMin,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: trip.score >= 90
                        ? AppColors.scoreExcellent.withValues(alpha: 0.1)
                        : trip.score >= 70
                        ? AppColors.scoreGood.withValues(alpha: 0.1)
                        : trip.score >= 50
                        ? AppColors.scoreAverage.withValues(alpha: 0.1)
                        : AppColors.scorePoor.withValues(alpha: 0.1),
                    border: Border.all(
                      color: trip.score >= 90
                          ? AppColors.scoreExcellent
                          : trip.score >= 70
                          ? AppColors.scoreGood
                          : trip.score >= 50
                          ? AppColors.scoreAverage
                          : AppColors.scorePoor,
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      trip.score.toString(),
                      style: TextStyle(
                        fontSize: 40.spMin,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.spMin),
                Text(startTimeStr, style: AppStyles.tsS14W400CB3B3B3),
              ],
            ),
          ),

          SizedBox(height: 24.spMin),

          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16.spMin,
            crossAxisSpacing: 16.spMin,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('Distance', '$distanceKm km', Icons.route),
              _buildStatCard('Duration', durationStr, Icons.timer),
              _buildStatCard('Top Speed', '$topSpeedKmH km/h', Icons.speed),
              _buildStatCard('Avg Speed', '$avgSpeedKmH km/h', Icons.moving),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16.spMin),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16.spMin),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 20.spMin, color: AppColors.primaryLight),
              SizedBox(width: 8.spMin),
              Text(title, style: AppStyles.tsS12W400C666666),
            ],
          ),
          SizedBox(height: 8.spMin),
          Text(value, style: AppStyles.tsS20W600CFFFFFF),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final String hours = duration.inHours > 0 ? '${duration.inHours}h ' : '';
    final String minutes = '${duration.inMinutes.remainder(60)}m';
    return '$hours$minutes';
  }
}
