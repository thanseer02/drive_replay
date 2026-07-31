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
        title: Text('Trip Recording', style: Theme.of(context).textTheme.titleLarge),
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
                child: _buildTelemetryDashboard(context, vm),
              ),
              _buildControlPanel(context, vm),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTelemetryDashboard(BuildContext context, TripRecordViewModel vm) {
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
            style: Theme.of(context).textTheme.displayLarge,
          ).animate(target: vm.state == TripState.recording ? 1 : 0).shimmer(duration: 2.seconds),
          Text(
            'km/h',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.grey),
          ),
          
          const SizedBox(height: 48),
          
          // Secondary Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSecondaryStat(context, 'Distance', '${vm.totalDistanceKm.toStringAsFixed(2)} km'),
              Container(width: 1, height: 40, color: Colors.white12),
              _buildSecondaryStat(context, 'Time', vm.formattedDuration),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
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
          context: context,
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
              context: context,
              label: 'PAUSE',
              color: Colors.orange,
              icon: Icons.pause,
              onTap: () => vm.pauseTrip(),
              isSmall: true,
            ),
            _buildBigButton(
              context: context,
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
              context: context,
              label: 'RESUME',
              color: Colors.green,
              icon: Icons.play_arrow,
              onTap: () => vm.resumeTrip(),
              isSmall: true,
            ),
            _buildBigButton(
              context: context,
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
    required BuildContext context,
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
