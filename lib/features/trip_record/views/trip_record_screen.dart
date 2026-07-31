import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:drive_replay/core/di/dependency_injection.dart';
import 'package:drive_replay/core/theme/app_colors.dart';
import 'package:drive_replay/features/trip_record/viewmodels/trip_record_viewmodel.dart';

class TripRecordScreen extends StatelessWidget {
  const TripRecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => locator<TripRecordViewModel>(),
      child: const _TripRecordView(),
    );
  }
}

class _TripRecordView extends StatelessWidget {
  const _TripRecordView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trip Recording', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Consumer<TripRecordViewModel>(
          builder: (context, vm, child) {
            // Only allow back navigation if not recording
            if (vm.state == TripState.recording) {
              return const SizedBox();
            }
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            );
          },
        ),
      ),
      body: Consumer<TripRecordViewModel>(
        builder: (context, vm, child) {
          return Column(
            children: [
              Expanded(
                child: _buildTelemetryDashboard(vm),
              ),
              _buildControlPanel(context, vm),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTelemetryDashboard(TripRecordViewModel vm) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: vm.state == TripState.recording ? Colors.green.withValues(alpha: 0.5) : Colors.transparent,
          width: 2,
        ),
        boxShadow: vm.state == TripState.recording
            ? [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.1),
                  blurRadius: 30,
                  spreadRadius: 10,
                )
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Speed
          Text(
            vm.currentSpeedKmh.toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 120,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.0,
            ),
          ).animate(target: vm.state == TripState.recording ? 1 : 0).shimmer(duration: 2.seconds),
          const Text(
            'km/h',
            style: TextStyle(
              fontSize: 24,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Secondary Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSecondaryStat('Distance', '${vm.totalDistanceKm.toStringAsFixed(2)} km'),
              Container(width: 1, height: 40, color: Colors.white12),
              _buildSecondaryStat('Time', vm.formattedDuration),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildControlPanel(BuildContext context, TripRecordViewModel vm) {
    return Container(
      padding: const EdgeInsets.only(bottom: 48, top: 24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildButtonsForState(context, vm),
      ),
    );
  }

  Widget _buildButtonsForState(BuildContext context, TripRecordViewModel vm) {
    switch (vm.state) {
      case TripState.idle:
        return _buildBigButton(
          label: 'START TRIP',
          color: Colors.green,
          icon: Icons.play_arrow,
          onTap: () => vm.startTrip(),
        );
      case TripState.recording:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBigButton(
              label: 'PAUSE',
              color: Colors.orange,
              icon: Icons.pause,
              onTap: () => vm.pauseTrip(),
              isSmall: true,
            ),
            _buildBigButton(
              label: 'STOP',
              color: Colors.red,
              icon: Icons.stop,
              onTap: () async {
                await vm.stopTrip();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              isSmall: true,
            ),
          ],
        );
      case TripState.paused:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBigButton(
              label: 'RESUME',
              color: Colors.green,
              icon: Icons.play_arrow,
              onTap: () => vm.resumeTrip(),
              isSmall: true,
            ),
            _buildBigButton(
              label: 'STOP',
              color: Colors.red,
              icon: Icons.stop,
              onTap: () async {
                await vm.stopTrip();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              isSmall: true,
            ),
          ],
        );
    }
  }

  Widget _buildBigButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    bool isSmall = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isSmall ? 150 : 250,
        height: 80,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
