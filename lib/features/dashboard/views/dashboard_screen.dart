import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drive_replay/core/di/dependency_injection.dart';
import 'package:drive_replay/core/theme/app_colors.dart';
import 'package:drive_replay/features/dashboard/viewmodels/dashboard_viewmodel.dart';
import 'package:drive_replay/features/history/views/trip_history_screen.dart';
import 'package:drive_replay/features/analytics/views/analytics_screen.dart';

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
          title: const Text('Drive Replay', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  _buildStatsGrid(vm),
                  const SizedBox(height: 24),
                  const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                  const SizedBox(height: 24),
                  const Text('System Health', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                vm.isRecording ? 'GPS tracking active' : 'Vehicle is parked',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(DashboardViewModel vm) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            title: 'Today\'s Distance',
            value: '${(vm.todayDistance / 1000).toStringAsFixed(1)} km',
            icon: Icons.route,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatBox(
            title: 'Total Trips',
            value: '${vm.totalTrips}',
            icon: Icons.history,
            color: Colors.orangeAccent,
          ),
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
          onTap: () {
            // Navigator.push(context, MaterialPageRoute(builder: (_) => const TripRecordScreen()));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip Recording UI coming soon')));
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          ListTile(
            leading: Icon(Icons.gps_fixed, color: Colors.green),
            title: Text('GPS Signal'),
            trailing: Text('Excellent', style: TextStyle(color: Colors.green)),
          ),
          Divider(height: 1, color: Colors.white12),
          ListTile(
            leading: Icon(Icons.security, color: Colors.green),
            title: Text('Permissions'),
            trailing: Text('Granted', style: TextStyle(color: Colors.green)),
          ),
          Divider(height: 1, color: Colors.white12),
          ListTile(
            leading: Icon(Icons.storage, color: Colors.green),
            title: Text('Local Storage'),
            trailing: Text('Healthy', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
