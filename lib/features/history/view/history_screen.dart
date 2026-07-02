import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../utils/colors.dart';
import '../../../utils/styles.dart';
import '../view_model/history_viewmodel.dart';
import '../../trip_recording/model/trip_model.dart';
import 'trip_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  static const String routeName = '/history';

  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryViewModel>().loadTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HistoryViewModel>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Trip History', style: AppStyles.tsS20W600CFFFFFF),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : viewModel.trips.isEmpty
              ? _buildEmptyState()
              : _buildTripsList(viewModel.trips, viewModel),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80.spMin, color: AppColors.textDisabled),
          SizedBox(height: 16.spMin),
          Text(
            'No trips recorded yet',
            style: AppStyles.tsS16W400CFFFFFF.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList(List<TripModel> trips, HistoryViewModel viewModel) {
    return ListView.separated(
      padding: EdgeInsets.all(16.spMin),
      itemCount: trips.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.spMin),
      itemBuilder: (context, index) {
        final trip = trips[index];
        final distanceKm = (trip.distanceInMeters / 1000).toStringAsFixed(1);
        final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(trip.startTime);
        
        return Dismissible(
          key: Key(trip.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20.spMin),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(12.spMin),
            ),
            child: const Icon(Icons.delete, color: AppColors.white),
          ),
          onDismissed: (_) {
            viewModel.deleteTrip(trip.id);
          },
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TripDetailScreen(trip: trip),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(16.spMin),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12.spMin),
            ),
            child: Row(
              children: [
                Container(
                  width: 50.spMin,
                  height: 50.spMin,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      trip.score.toString(),
                      style: TextStyle(
                        fontSize: 18.spMin,
                        fontWeight: FontWeight.bold,
                        color: trip.score >= 90 ? AppColors.scoreExcellent : AppColors.scoreAverage,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.spMin),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateStr, style: AppStyles.tsS16W600CFFFFFF),
                      SizedBox(height: 4.spMin),
                      Text('$distanceKm km • Max ${(trip.topSpeed * 3.6).toStringAsFixed(0)} km/h', 
                           style: AppStyles.tsS14W400CB3B3B3),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ), // Container
          ), // GestureDetector
        ); // Dismissible
      },
    );
  }
}
