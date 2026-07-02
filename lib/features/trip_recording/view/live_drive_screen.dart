import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
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
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.spMin, vertical: 20.spMin),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24.spMin),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 15,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Speed', style: AppStyles.tsS14W400CB3B3B3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(speedKmH, style: TextStyle(
                    fontSize: 48.spMin,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryLight,
                  )),
                  SizedBox(width: 8.spMin),
                  Text('km/h', style: AppStyles.tsS16W400CFFFFFF),
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
              width: 70.spMin,
              height: 70.spMin,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stop, color: AppColors.white, size: 36),
            ),
          ),
        ],
      ),
    );
  }
}
