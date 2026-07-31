import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drive_replay/core/di/dependency_injection.dart';
import 'package:drive_replay/core/theme/app_colors.dart';
import 'package:drive_replay/features/dashboard/viewmodels/dashboard_viewmodel.dart';
import 'package:drive_replay/features/trip_record/views/trip_record_screen.dart';
import 'package:drive_replay/features/history/views/trip_history_screen.dart';
import 'package:drive_replay/features/analytics/views/analytics_screen.dart';
import 'package:drive_replay/core/permissions/viewmodels/permission_viewmodel.dart';
import 'package:drive_replay/core/permissions/models/permission_state.dart';
import 'package:drive_replay/core/permissions/views/permissions_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:drive_replay/features/debug/views/debug_dashboard_screen.dart' as drive_replay_debug;
import 'package:drive_replay/features/settings/viewmodels/settings_viewmodel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => locator<DashboardViewModel>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Drive Replay', style: Theme.of(context).textTheme.titleLarge),
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        body: Consumer<DashboardViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: vm.refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatusCard(vm),
                  const SizedBox(height: 16),
                  Consumer<SettingsViewModel>(
                    builder: (context, settingsVm, child) {
                      return _buildStatsGrid(vm, settingsVm);
                    },
                  ),
                  const SizedBox(height: 24),
                  Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onLongPress: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const drive_replay_debug.DebugDashboardScreen()));
                    },
                    child: Text('System Health', style: Theme.of(context).textTheme.titleLarge),
                  ),
                  const SizedBox(height: 16),
                  _buildSystemHealth(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard(DashboardViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: vm.isRecording ? Colors.green.withValues(alpha: 0.2) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vm.isRecording ? Colors.green : Colors.transparent),
      ),
      child: Row(
        children: [
          Icon(
            vm.isRecording ? Icons.fiber_manual_record : Icons.local_parking,
            color: vm.isRecording ? Colors.green : Colors.grey,
            size: 32,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vm.isRecording ? 'Recording in progress' : 'Ready to drive',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                vm.isRecording ? 'GPS tracking active' : 'Vehicle is parked',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(DashboardViewModel vm, SettingsViewModel settingsVm) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatBox(
                title: 'Today',
                value: '${settingsVm.convertDistance(vm.todayDistance).toStringAsFixed(1)} ${settingsVm.distanceUnitString}',
                icon: Icons.today,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatBox(
                title: 'This Week',
                value: '${settingsVm.convertDistance(vm.weeklyDistance).toStringAsFixed(1)} ${settingsVm.distanceUnitString}',
                icon: Icons.calendar_view_week,
                color: Colors.purpleAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatBox(
                title: 'This Month',
                value: '${settingsVm.convertDistance(vm.monthlyDistance).toStringAsFixed(1)} ${settingsVm.distanceUnitString}',
                icon: Icons.calendar_month,
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatBox(
                title: 'Lifetime',
                value: '${settingsVm.convertDistance(vm.lifetimeDistance).toStringAsFixed(1)} ${settingsVm.distanceUnitString}',
                icon: Icons.public,
                color: Colors.greenAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ActionButton(
          icon: Icons.play_arrow,
          label: 'Start Trip',
          onTap: () async {
            final permVm = context.read<PermissionViewModel>();
            if (permVm.getState(Permission.location) == AppPermissionState.granted &&
                permVm.getState(Permission.locationAlways) == AppPermissionState.granted &&
                permVm.getState(Permission.ignoreBatteryOptimizations) == AppPermissionState.granted &&
                permVm.getState(Permission.notification) == AppPermissionState.granted) {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const TripRecordScreen()));
              if (context.mounted) {
                await context.read<DashboardViewModel>().refresh();
              }
            } else {
              // Route to permissions screen
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const PermissionsScreen()));
            }
          },
        ),
        _ActionButton(
          icon: Icons.list,
          label: 'History',
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TripHistoryScreen()));
          },
        ),
        _ActionButton(
          icon: Icons.bar_chart,
          label: 'Analytics',
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
          },
        ),
      ],
    );
  }

  Widget _buildSystemHealth() {
    return Consumer<PermissionViewModel>(
      builder: (context, permVm, child) {
        final allGranted = permVm.getState(Permission.location) == AppPermissionState.granted &&
            permVm.getState(Permission.locationAlways) == AppPermissionState.granted &&
            permVm.getState(Permission.ignoreBatteryOptimizations) == AppPermissionState.granted &&
            permVm.getState(Permission.notification) == AppPermissionState.granted;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.gps_fixed, color: Colors.green),
                title: Text('GPS Signal'),
                trailing: Text('Waiting for Trip', style: TextStyle(color: Colors.grey)),
              ),
              const Divider(height: 1, color: Colors.white12),
              ListTile(
                leading: Icon(Icons.security, color: allGranted ? Colors.green : Colors.red),
                title: const Text('Permissions'),
                trailing: Text(
                  allGranted ? 'Granted' : 'Action Required',
                  style: TextStyle(color: allGranted ? Colors.green : Colors.red),
                ),
                onTap: () {
                  if (!allGranted) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PermissionsScreen()));
                  }
                },
              ),
              const Divider(height: 1, color: Colors.white12),
              const ListTile(
                leading: Icon(Icons.storage, color: Colors.green),
                title: Text('Local Storage'),
                trailing: Text('Healthy', style: TextStyle(color: Colors.green)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
