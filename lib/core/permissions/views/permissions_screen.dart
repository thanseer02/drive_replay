import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drive_replay/core/theme/app_colors.dart';
import 'package:drive_replay/core/permissions/viewmodels/permission_viewmodel.dart';
import 'package:drive_replay/core/permissions/models/permission_state.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Setup Requirements', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<PermissionViewModel>(
        builder: (context, vm, child) {
          final isLocationGranted = vm.getState(Permission.location) == AppPermissionState.granted;
          final isBgLocationGranted = vm.getState(Permission.locationAlways) == AppPermissionState.granted;
          final isNotificationGranted = vm.getState(Permission.notification) == AppPermissionState.granted;
          final isBatteryIgnored = vm.getState(Permission.ignoreBatteryOptimizations) == AppPermissionState.granted;

          final allDone = isLocationGranted && isBgLocationGranted && isNotificationGranted && isBatteryIgnored;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Drive Replay needs your permission to track trips accurately.',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView(
                    children: [
                      _buildPermissionItem(
                        context: context,
                        icon: Icons.location_on,
                        title: 'Precise Location',
                        description: 'Required to track your speed and distance.',
                        isGranted: isLocationGranted,
                        onTap: () => vm.requestLocation(),
                      ),
                      _buildPermissionItem(
                        context: context,
                        icon: Icons.location_disabled,
                        title: 'Background Tracking',
                        description: 'Required to continue recording when the screen is locked or the app is minimized. Select "Allow all the time".',
                        isGranted: isBgLocationGranted,
                        isEnabled: isLocationGranted, // Must have fine location first
                        onTap: () => vm.requestBackgroundLocation(),
                      ),
                      _buildPermissionItem(
                        context: context,
                        icon: Icons.notifications,
                        title: 'Notifications',
                        description: 'Required to show the active recording status in your notification tray.',
                        isGranted: isNotificationGranted,
                        onTap: () => vm.requestNotifications(),
                      ),
                      _buildPermissionItem(
                        context: context,
                        icon: Icons.battery_charging_full,
                        title: 'Battery Optimization',
                        description: 'Prevents Android from killing the tracker to save battery.',
                        isGranted: isBatteryIgnored,
                        onTap: () => vm.requestBatteryOptimization(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: allDone ? AppColors.primary : Colors.grey[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: allDone ? () => Navigator.of(context).pop() : null,
                    child: Text(
                      allDone ? 'Continue to App' : 'Grant permissions to continue',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                if (!allDone)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Center(
                      child: TextButton(
                        onPressed: () => vm.openSettings(),
                        child: const Text('Open App Settings', style: TextStyle(color: AppColors.primary)),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPermissionItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    bool isEnabled = true,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isGranted ? Colors.green : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: isGranted ? Colors.green : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            if (isGranted)
              const Icon(Icons.check_circle, color: Colors.green, size: 32)
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isEnabled ? onTap : null,
                child: const Text('Grant', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}
