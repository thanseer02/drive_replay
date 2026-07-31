import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drive_replay/core/theme/app_colors.dart';
import 'package:drive_replay/core/theme/app_theme.dart';
import 'package:drive_replay/features/debug/viewmodels/debug_viewmodel.dart';
import 'package:drive_replay/features/trip_record/viewmodels/trip_record_viewmodel.dart';
import 'package:drive_replay/core/di/dependency_injection.dart';
import 'package:drive_replay/core/services/local_db/app_database.dart';

class DebugDashboardScreen extends StatelessWidget {
  const DebugDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DebugViewModel(locator<AppDatabase>())),
        ChangeNotifierProvider(create: (_) => locator<TripRecordViewModel>()),
      ],
      child: const _DebugDashboardContent(),
    );
  }
}

class _DebugDashboardContent extends StatelessWidget {
  const _DebugDashboardContent();

  @override
  Widget build(BuildContext context) {
    final debugVm = context.watch<DebugViewModel>();
    final tripVm = context.watch<TripRecordViewModel>(); // Assuming it is in scope, or we'd inject it here

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Developer Debug', style: AppTextStyles.tss18w700),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildCard('Background Telemetry', [
            _buildRow('Foreground Service', debugVm.isForegroundServiceRunning ? 'RUNNING' : 'STOPPED'),
            _buildRow('Total DB Points', debugVm.totalDbPoints.toString()),
            _buildRow('State (Provider)', tripVm.state.name),
          ]),
          const SizedBox(height: 16),
          _buildCard('Raw GPS Sensor', [
            _buildRow('Latitude', tripVm.latitude.toStringAsFixed(6)),
            _buildRow('Longitude', tripVm.longitude.toStringAsFixed(6)),
            _buildRow('Altitude', '${tripVm.altitude.toStringAsFixed(2)} m'),
            _buildRow('Heading', '${tripVm.heading.toStringAsFixed(2)}°'),
            _buildRow('Speed', '${(tripVm.currentSpeed * 3.6).toStringAsFixed(1)} km/h'),
            _buildRow('Accuracy', '${tripVm.accuracy.toStringAsFixed(1)} m'),
          ]),
          const SizedBox(height: 16),
          _buildCard('Calculated Distance', [
            _buildRow('Distance Since Last Point', '${tripVm.distanceSinceLast.toStringAsFixed(2)} m'),
            _buildRow('Current Trip Distance', '${tripVm.totalDistance.toStringAsFixed(2)} m'),
          ]),
          const SizedBox(height: 16),
          _buildCard('System Timestamps', [
            _buildRow('Last GPS Update', tripVm.lastUpdateTime?.toIso8601String() ?? 'N/A'),
          ]),
        ],
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.tss14w700.copyWith(color: AppColors.primary)),
          const Divider(color: Colors.white10, height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.tss14w400.copyWith(color: Colors.white70)),
          Text(value, style: AppTextStyles.tss14w700),
        ],
      ),
    );
  }
}
