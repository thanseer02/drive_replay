import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drive_replay/core/di/dependency_injection.dart';
import 'package:drive_replay/core/theme/app_colors.dart';
import 'package:drive_replay/features/replay/viewmodels/replay_viewmodel.dart';
import 'package:drive_replay/features/replay/widgets/route_painter.dart';

class ReplayScreen extends StatefulWidget {
  final int tripId;

  const ReplayScreen({super.key, required this.tripId});

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final vm = locator<ReplayViewModel>();
        vm.loadTrip(widget.tripId);
        return vm;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Trip Replay', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        body: Consumer<ReplayViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.points.isEmpty) {
              return const Center(child: Text('No points recorded for this trip.'));
            }

            return Stack(
              children: [
                // 1. Map Canvas
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 120.0), // Space for bottom bar
                    child: CustomPaint(
                      painter: RoutePainter(
                        points: vm.points,
                        currentLat: vm.currentLatitude,
                        currentLng: vm.currentLongitude,
                        currentHeading: vm.currentHeading,
                      ),
                    ),
                  ),
                ),
                
                // 2. HUD
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: _buildHud(vm),
                ),
                
                // 3. Bottom Controls
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomBar(vm),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHud(ReplayViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _HudItem(label: 'Speed', value: '${(vm.currentSpeed * 3.6).toStringAsFixed(1)} km/h'),
          _HudItem(label: 'Heading', value: '${vm.currentHeading.toStringAsFixed(0)}°'),
          _HudItem(label: 'Alt', value: '${vm.currentAltitude.toStringAsFixed(0)} m'),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ReplayViewModel vm) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 32, left: 16, right: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(vm.formattedSimTime, style: const TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: Slider(
                  value: vm.progress,
                  onChanged: (val) {
                    vm.seekTo(val);
                  },
                  activeColor: AppColors.primary,
                  inactiveColor: Colors.white24,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(vm.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                iconSize: 64,
                color: AppColors.primary,
                onPressed: () => vm.togglePlayback(),
              ),
              const SizedBox(width: 32),
              PopupMenuButton<double>(
                initialValue: vm.playbackSpeed,
                onSelected: (speed) => vm.setPlaybackSpeed(speed),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('${vm.playbackSpeed.toInt()}x', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 1.0, child: Text('1x Speed')),
                  const PopupMenuItem(value: 2.0, child: Text('2x Speed')),
                  const PopupMenuItem(value: 4.0, child: Text('4x Speed')),
                  const PopupMenuItem(value: 8.0, child: Text('8x Speed')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HudItem extends StatelessWidget {
  final String label;
  final String value;

  const _HudItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
