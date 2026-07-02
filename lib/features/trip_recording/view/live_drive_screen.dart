import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../../utils/colors.dart';
import '../../../utils/styles.dart';
import '../view_model/trip_viewmodel.dart';

class LiveDriveScreen extends StatefulWidget {
  static const String routeName = '/live_drive';

  const LiveDriveScreen({super.key});

  @override
  State<LiveDriveScreen> createState() => _LiveDriveScreenState();
}

class _LiveDriveScreenState extends State<LiveDriveScreen> {
  final MapController _mapController = MapController();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripViewModel>().startTrip();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TripViewModel>();
    final pos = viewModel.currentPosition;
    
    // Default location if GPS hasn't locked yet
    final center = pos != null ? LatLng(pos.latitude, pos.longitude) : const LatLng(51.5, -0.09);

    if (pos != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(center, 18.0);
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 18.0,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.drivereplay.app',
              ),
              if (pos != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          // Speed Overlay
          Positioned(
            bottom: 40.spMin,
            left: 20.spMin,
            right: 20.spMin,
            child: _buildBottomPanel(viewModel),
          ),
          
          // Back Button
          Positioned(
            top: 50.spMin,
            left: 20.spMin,
            child: CircleAvatar(
              backgroundColor: AppColors.surface,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.white),
                onPressed: () {
                  viewModel.stopTrip();
                  Navigator.pop(context);
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomPanel(TripViewModel viewModel) {
    final speedKmH = (viewModel.currentSpeed * 3.6).toStringAsFixed(0);
    final topSpeedKmH = ((viewModel.currentTrip?.topSpeed ?? 0.0) * 3.6).toStringAsFixed(0);
    final distanceKm = ((viewModel.currentTrip?.distanceInMeters ?? 0.0) / 1000).toStringAsFixed(2);
    final startTimeStr = viewModel.currentTrip != null 
        ? DateFormat('h:mm a').format(viewModel.currentTrip!.startTime)
        : '--:--';
    
    final duration = viewModel.tripDuration;
    final String durationStr = '${duration.inHours > 0 ? '${duration.inHours}:' : ''}'
        '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:'
        '${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(30.spMin),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(24.spMin),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(30.spMin),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Section: Speed & Stop Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CURRENT SPEED', style: AppStyles.tsS12W400C666666.copyWith(letterSpacing: 1.2)),
                      SizedBox(height: 4.spMin),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            speedKmH, 
                            style: TextStyle(
                              fontSize: 56.spMin,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primaryLight,
                              height: 1.0,
                            )
                          ),
                          SizedBox(width: 8.spMin),
                          Text('km/h', style: AppStyles.tsS16W600CFFFFFF.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      viewModel.stopTrip();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 64.spMin,
                      height: 64.spMin,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.error, AppColors.error.withValues(alpha: 0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.stop_rounded, color: AppColors.white, size: 36),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24.spMin),
              Container(
                height: 1,
                color: AppColors.white.withValues(alpha: 0.05),
              ),
              SizedBox(height: 24.spMin),
              
              // Bottom Section: Grid of Stats
              Row(
                children: [
                  Expanded(child: _buildDetailItem(Icons.timer_outlined, 'Duration', durationStr)),
                  Container(width: 1, height: 40.spMin, color: AppColors.white.withValues(alpha: 0.05)),
                  Expanded(child: _buildDetailItem(Icons.route_outlined, 'Distance', '$distanceKm km')),
                ],
              ),
              SizedBox(height: 16.spMin),
              Row(
                children: [
                  Expanded(child: _buildDetailItem(Icons.speed_outlined, 'Top Speed', '$topSpeedKmH km/h')),
                  Container(width: 1, height: 40.spMin, color: AppColors.white.withValues(alpha: 0.05)),
                  Expanded(child: _buildDetailItem(Icons.access_time_outlined, 'Started', startTimeStr)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.spMin),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.spMin),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.spMin),
            ),
            child: Icon(icon, color: AppColors.primaryLight, size: 16.spMin),
          ),
          SizedBox(width: 12.spMin),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppStyles.tsS12W400C666666),
                SizedBox(height: 2.spMin),
                Text(value, style: AppStyles.tsS14W400CFFFFFF.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
