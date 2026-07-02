import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../history/view/history_screen.dart';
import '../../settings/view/settings_screen.dart';
import '../../trip_recording/view/live_drive_screen.dart';
import '../../history/view_model/history_viewmodel.dart';
import '../../../utils/colors.dart';
import '../../../utils/styles.dart';

class DashboardScreen extends StatefulWidget {
  static const String routeName = '/dashboard';

  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryViewModel>().loadTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyViewModel = context.watch<HistoryViewModel>();
    final tripsCount = historyViewModel.trips.length;
    final totalDistance = historyViewModel.trips.fold(
      0.0,
      (sum, trip) => sum + trip.distanceInMeters,
    );
    final distanceKm = (totalDistance / 1000).toStringAsFixed(1);

    // Calculate average score
    final avgScore = tripsCount > 0
        ? (historyViewModel.trips.fold(0, (sum, trip) => sum + trip.score) /
                  tripsCount)
              .round()
        : 100;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 20.spMin,
            vertical: 16.spMin,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopNav(context),
              SizedBox(height: 32.spMin),
              _buildHeader(),
              SizedBox(height: 32.spMin),
              _buildStatsGrid(tripsCount, distanceKm, avgScore),
              SizedBox(height: 48.spMin),
              _buildStartTripButton(context),
              SizedBox(height: 40.spMin),
              if (historyViewModel.trips.isNotEmpty)
                _buildRecentTripPreview(context, historyViewModel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNav(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.spMin),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.spMin),
              ),
              child: Icon(
                Icons.directions_car,
                color: AppColors.primary,
                size: 28.spMin,
              ),
            ),
            SizedBox(width: 12.spMin),
            Text('Drive Replay', style: AppStyles.tsS20W600CFFFFFF),
          ],
        ),
        Row(
          children: [
            _buildNavIcon(
              Icons.history,
              () => Navigator.pushNamed(context, HistoryScreen.routeName),
            ),
            SizedBox(width: 12.spMin),
            _buildNavIcon(
              Icons.settings,
              () => Navigator.pushNamed(context, SettingsScreen.routeName),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10.spMin),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.white, size: 24.spMin),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ready to drive?', style: AppStyles.tsS32W700CFFFFFF),
        SizedBox(height: 8.spMin),
        Text(
          'Your smart black box is standing by.',
          style: AppStyles.tsS16W400CFFFFFF.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(int trips, String distance, int score) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Avg Score',
            value: score.toString(),
            icon: Icons.speed,
            color: score >= 90
                ? AppColors.scoreExcellent
                : AppColors.scoreAverage,
          ),
        ),
        SizedBox(width: 16.spMin),
        Expanded(
          child: Column(
            children: [
              _buildSmallStatCard('Trips', trips.toString(), Icons.route),
              SizedBox(height: 16.spMin),
              _buildSmallStatCard('Distance', '$distance km', Icons.map),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(20.spMin),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(24.spMin),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(12.spMin),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28.spMin),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 42.spMin,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(title, style: AppStyles.tsS14W400CB3B3B3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String title, String value, IconData icon) {
    return Container(
      width: double.infinity,
      height: 80.spMin,
      padding: EdgeInsets.symmetric(horizontal: 16.spMin),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20.spMin),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24.spMin),
          SizedBox(width: 12.spMin),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: AppStyles.tsS20W600CFFFFFF),
              Text(title, style: AppStyles.tsS12W400C666666),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStartTripButton(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () async {
          final bool? start = await showModalBottomSheet<bool>(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              padding: EdgeInsets.all(24.spMin),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30.spMin)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Start Trip', style: AppStyles.tsS24W700CFFFFFF),
                  SizedBox(height: 16.spMin),
                  Text(
                    'Are you ready to start recording a new trip?',
                    textAlign: TextAlign.center,
                    style: AppStyles.tsS16W400CFFFFFF.copyWith(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 32.spMin),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16.spMin),
                            backgroundColor: AppColors.surfaceLight,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.spMin)),
                          ),
                          child: Text('Cancel', style: AppStyles.tsS16W600CFFFFFF.copyWith(color: AppColors.textSecondary)),
                        ),
                      ),
                      SizedBox(width: 16.spMin),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16.spMin),
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.spMin)),
                          ),
                          child: Text('Start', style: AppStyles.tsS16W600CFFFFFF),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.spMin),
                ],
              ),
            ),
          );
          if (start == true && context.mounted) {
            Navigator.pushNamed(context, LiveDriveScreen.routeName);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: 16.spMin,
            horizontal: 24.spMin,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35.spMin),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Start Trip',
                style: AppStyles.tsS20W600CFFFFFF.copyWith(letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTripPreview(
    BuildContext context,
    HistoryViewModel viewModel,
  ) {
    final latestTrip = viewModel.trips.first;
    final dateStr = DateFormat(
      'MMM d, yyyy • h:mm a',
    ).format(latestTrip.startTime);
    final distanceKm = (latestTrip.distanceInMeters / 1000).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Trip', style: AppStyles.tsS16W600CFFFFFF),
            GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, HistoryScreen.routeName),
              child: Text(
                'View All',
                style: AppStyles.tsS14W400CB3B3B3.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.spMin),
        Container(
          padding: EdgeInsets.all(16.spMin),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16.spMin),
            border: Border.all(color: AppColors.surface, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 45.spMin,
                height: 45.spMin,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.route,
                  color: AppColors.primary,
                  size: 24.spMin,
                ),
              ),
              SizedBox(width: 16.spMin),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateStr, style: AppStyles.tsS14W400CB3B3B3),
                    SizedBox(height: 4.spMin),
                    Text('$distanceKm km', style: AppStyles.tsS16W600CFFFFFF),
                  ],
                ),
              ),
              Text(
                '${latestTrip.score}',
                style: TextStyle(
                  fontSize: 22.spMin,
                  fontWeight: FontWeight.bold,
                  color: latestTrip.score >= 90
                      ? AppColors.scoreExcellent
                      : AppColors.scoreAverage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
