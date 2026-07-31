import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:drive_replay/core/di/dependency_injection.dart';
import 'package:drive_replay/core/theme/app_colors.dart';
import 'package:drive_replay/core/theme/app_theme.dart';
import 'package:drive_replay/features/trip_record/viewmodels/trip_record_viewmodel.dart';
import 'package:drive_replay/features/settings/viewmodels/settings_viewmodel.dart';

class TripRecordScreen extends StatelessWidget {
  const TripRecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => locator<TripRecordViewModel>()),
      ],
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
      body: Consumer2<TripRecordViewModel, SettingsViewModel>(
        builder: (context, vm, settingsVm, child) {
          return Column(
            children: [
              Expanded(
                child: _buildTelemetryDashboard(context, vm, settingsVm),
              ),
              _buildControlPanel(context, vm),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTelemetryDashboard(BuildContext context, TripRecordViewModel vm, SettingsViewModel settingsVm) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
            settingsVm.convertSpeed(vm.currentSpeed).toStringAsFixed(0),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ).animate(target: vm.state == TripState.recording ? 1 : 0).shimmer(duration: 2.seconds),
          Text(
            settingsVm.speedUnitString,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.grey),
          ),
          
          const SizedBox(height: 48),
          
          // Secondary Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSecondaryStat(context, 'Distance', '${settingsVm.convertDistance(vm.totalDistance).toStringAsFixed(2)} ${settingsVm.distanceUnitString}'),
              Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.3)),
              _buildSecondaryStat(context, 'Time', vm.formattedDuration),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSecondaryStat(context, 'Avg Speed', '${settingsVm.convertSpeed(vm.averageSpeed).toStringAsFixed(1)} ${settingsVm.speedUnitString}'),
              Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.3)),
              _buildSecondaryStat(context, 'Max Speed', '${settingsVm.convertSpeed(vm.maxSpeed).toStringAsFixed(1)} ${settingsVm.speedUnitString}'),
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
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
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
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: Text('Start Trip?', style: AppTextStyles.tss18w700),
                content: Text('Are you ready to begin recording your trip?', style: AppTextStyles.tss14w400.copyWith(color: Colors.white70)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Cancel', style: AppTextStyles.tss14w400.copyWith(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      vm.startTrip();
                    },
                    child: Text('Start', style: AppTextStyles.tss14w700.copyWith(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
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
