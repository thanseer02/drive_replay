import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drive_tracker/features/settings/viewmodel/settings_viewmodel.dart';
import 'package:drive_tracker/features/history/viewmodel/history_viewmodel.dart';
import 'package:drive_tracker/widgets/adaptive_layout.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Mock states for permissions
  bool _locationGranted = true;
  bool _notificationsGranted = false;
  bool _motionFitnessGranted = true;
  bool _batteryOptimizationIgnored = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsViewModel>();
    final bool isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final strokeColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final Widget phoneBody = ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      children: [
        const SizedBox(height: 8),

        // Section: General Preferences
        _buildSectionHeader(theme, 'General preferences'),
        Card(
          elevation: 0,
          color: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: strokeColor),
          ),
          child: Column(
            children: [
              SwitchListTile(
                value: settings.isDarkMode,
                title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Adjust color themes for low light views'),
                secondary: Icon(
                  settings.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: settings.isDarkMode ? Colors.indigoAccent : Colors.amber,
                ),
                onChanged: (val) => settings.toggleDarkMode(val),
              ),
              Divider(height: 1, indent: 64, color: strokeColor),
              SwitchListTile(
                value: settings.useMetric,
                title: const Text('Use Metric Units', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(settings.useMetric
                    ? 'Telemetry shown in Kilometers (km, km/h)'
                    : 'Telemetry converted to Miles (mi, mph)'),
                secondary: const Icon(Icons.tune_rounded, color: Colors.blueAccent),
                onChanged: (val) => settings.toggleUseMetric(val),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Section: Device Background & Power Settings (Tesla Style)
        _buildSectionHeader(theme, 'Background & battery optimization'),
        Card(
          elevation: 0,
          color: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: strokeColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: SwitchListTile(
              value: _batteryOptimizationIgnored,
              activeThumbColor: theme.colorScheme.primary,
              title: const Text('Exclude from Battery Optimization', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Enable unrestricted background performance to avoid ride data capture drops'),
              secondary: Icon(
                _batteryOptimizationIgnored ? Icons.battery_charging_full_rounded : Icons.battery_saver_rounded,
                color: _batteryOptimizationIgnored ? const Color(0xFF10B981) : Colors.orangeAccent,
              ),
              onChanged: (val) {
                setState(() => _batteryOptimizationIgnored = val);
                _showToast(
                  context,
                  val
                      ? 'Battery optimization disabled. App allowed to run untruncated.'
                      : 'Battery optimization enabled (standard power policy).',
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Section: Permission manager
        _buildSectionHeader(theme, 'System permissions status'),
        Card(
          elevation: 0,
          color: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: strokeColor),
          ),
          child: Column(
            children: [
              _buildPermissionTile(
                title: 'GPS Location Services',
                desc: 'Needed to log distances mock coordinates',
                granted: _locationGranted,
                onToggle: (val) {
                  setState(() => _locationGranted = val);
                  _showToast(context, val ? 'GPS Location Mock access permitted' : 'GPS Location access disabled');
                },
              ),
              Divider(height: 1, indent: 64, color: strokeColor),
              _buildPermissionTile(
                title: 'System Notifications',
                desc: 'Show dashboard record status in system drawers',
                granted: _notificationsGranted,
                onToggle: (val) {
                  setState(() => _notificationsGranted = val);
                  _showToast(context, val ? 'Notifications permitted' : 'Notifications disabled');
                },
              ),
              Divider(height: 1, indent: 64, color: strokeColor),
              _buildPermissionTile(
                title: 'Physical Motion / Fitness Sensors',
                desc: 'Allows tracking to pause automatically when stopping',
                granted: _motionFitnessGranted,
                onToggle: (val) {
                  setState(() => _motionFitnessGranted = val);
                  _showToast(context, val ? 'Fitness sensors tracking permitted' : 'Sensors tracking disabled');
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Section: Maintenance
        _buildSectionHeader(theme, 'Security & maintenance'),
        Card(
          elevation: 0,
          color: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: strokeColor),
          ),
          child: ListTile(
            leading: const Icon(Icons.backspace_rounded, color: Colors.redAccent),
            title: const Text('Reset Application Database', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Erase all SQL telemetry logs and reset defaults'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _confirmReset(context),
          ),
        ),

        const SizedBox(height: 24),

        // Section: App info (premium Garmin Connect design details)
        _buildSectionHeader(theme, 'Vehicle Tracker Engine Details'),
        Card(
          elevation: 0,
          color: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: strokeColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildInfoRow('Engine Architecture', 'Clean + MVVM (Provider)'),
                Divider(height: 20, color: strokeColor),
                _buildInfoRow('Local Core DB', 'SQLite Persistent Cache'),
                Divider(height: 20, color: strokeColor),
                _buildInfoRow('Target Flutter Platform', 'Flutter 3.41.2 (FVM)'),
                Divider(height: 20, color: strokeColor),
                _buildInfoRow('Engine Release Version', '1.0.0 (Build 1)'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );

    final Widget tabletBody = TwoColumnLayout(
      showDivider: false,
      leftFlex: 1.0,
      rightFlex: 1.0,
      left: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          const SizedBox(height: 8),
          _buildSectionHeader(theme, 'General preferences'),
          Card(
            elevation: 0,
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: strokeColor),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.isDarkMode,
                  title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Adjust color themes for low light views'),
                  secondary: Icon(
                    settings.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: settings.isDarkMode ? Colors.indigoAccent : Colors.amber,
                  ),
                  onChanged: (val) => settings.toggleDarkMode(val),
                ),
                Divider(height: 1, indent: 64, color: strokeColor),
                SwitchListTile(
                  value: settings.useMetric,
                  title: const Text('Use Metric Units', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(settings.useMetric
                      ? 'Telemetry shown in Kilometers (km, km/h)'
                      : 'Telemetry converted to Miles (mi, mph)'),
                  secondary: const Icon(Icons.tune_rounded, color: Colors.blueAccent),
                  onChanged: (val) => settings.toggleUseMetric(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(theme, 'Background & battery optimization'),
          Card(
            elevation: 0,
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: strokeColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: SwitchListTile(
                value: _batteryOptimizationIgnored,
                activeThumbColor: theme.colorScheme.primary,
                title: const Text('Exclude from Battery Optimization', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Enable unrestricted background performance to avoid ride data capture drops'),
                secondary: Icon(
                  _batteryOptimizationIgnored ? Icons.battery_charging_full_rounded : Icons.battery_saver_rounded,
                  color: _batteryOptimizationIgnored ? const Color(0xFF10B981) : Colors.orangeAccent,
                ),
                onChanged: (val) {
                  setState(() => _batteryOptimizationIgnored = val);
                  _showToast(
                    context,
                    val
                        ? 'Battery optimization disabled. App allowed to run untruncated.'
                        : 'Battery optimization enabled (standard power policy).',
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      right: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          const SizedBox(height: 8),
          _buildSectionHeader(theme, 'System permissions status'),
          Card(
            elevation: 0,
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: strokeColor),
            ),
            child: Column(
              children: [
                _buildPermissionTile(
                  title: 'GPS Location Services',
                  desc: 'Needed to log distances mock coordinates',
                  granted: _locationGranted,
                  onToggle: (val) {
                    setState(() => _locationGranted = val);
                    _showToast(context, val ? 'GPS Location Mock access permitted' : 'GPS Location access disabled');
                  },
                ),
                Divider(height: 1, indent: 64, color: strokeColor),
                _buildPermissionTile(
                  title: 'System Notifications',
                  desc: 'Show dashboard record status in system drawers',
                  granted: _notificationsGranted,
                  onToggle: (val) {
                    setState(() => _notificationsGranted = val);
                    _showToast(context, val ? 'Notifications permitted' : 'Notifications disabled');
                  },
                ),
                Divider(height: 1, indent: 64, color: strokeColor),
                _buildPermissionTile(
                  title: 'Physical Motion / Fitness Sensors',
                  desc: 'Allows tracking to pause automatically when stopping',
                  granted: _motionFitnessGranted,
                  onToggle: (val) {
                    setState(() => _motionFitnessGranted = val);
                    _showToast(context, val ? 'Fitness sensors tracking permitted' : 'Sensors tracking disabled');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(theme, 'Security & maintenance'),
          Card(
            elevation: 0,
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: strokeColor),
            ),
            child: ListTile(
              leading: const Icon(Icons.backspace_rounded, color: Colors.redAccent),
              title: const Text('Reset Application Database', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Erase all SQL telemetry logs and reset defaults'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _confirmReset(context),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(theme, 'Vehicle Tracker Engine Details'),
          Card(
            elevation: 0,
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: strokeColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildInfoRow('Engine Architecture', 'Clean + MVVM (Provider)'),
                  Divider(height: 20, color: strokeColor),
                  _buildInfoRow('Local Core DB', 'SQLite Persistent Cache'),
                  Divider(height: 20, color: strokeColor),
                  _buildInfoRow('Target Flutter Platform', 'Flutter 3.41.2 (FVM)'),
                  Divider(height: 20, color: strokeColor),
                  _buildInfoRow('Engine Release Version', '1.0.0 (Build 1)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.brightness == Brightness.light
                ? [const Color(0xFFF1F5F9), const Color(0xFFFFFFFF)]
                : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PREFERENCES',
                      style: theme.textTheme.labelMedium?.copyWith(
                        letterSpacing: 3,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'App Settings',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: AdaptiveLayout(
                  phone: phoneBody,
                  tablet: tabletBody,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String desc,
    required bool granted,
    required ValueChanged<bool> onToggle,
  }) {
    return SwitchListTile(
      value: granted,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(desc),
      secondary: Icon(
        granted ? Icons.verified_user_rounded : Icons.gpp_maybe_rounded,
        color: granted ? const Color(0xFF10B981) : Colors.orangeAccent,
      ),
      onChanged: onToggle,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _showToast(BuildContext context, String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.colorScheme.secondary,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    final historyVM = context.read<HistoryViewModel>();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Purge Database?'),
        content: const Text('This deletes all recorded telemetry drives from the SQLite tables. You cannot revert this operation.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              historyVM.clearHistory();
              // Reset settings VM to defaults
              final settings = context.read<SettingsViewModel>();
              settings.toggleDarkMode(false);
              settings.toggleUseMetric(true);
              Navigator.pop(ctx);
              
              _showToast(context, 'SQLite database Tables purged. Reverted settings to system defaults.');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Purge Database'),
          ),
        ],
      ),
    );
  }
}
