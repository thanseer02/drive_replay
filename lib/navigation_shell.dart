import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:drive_tracker/widgets/adaptive_layout.dart';

class NavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const NavigationShell({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      // Phone: standard bottom NavigationBar
      phone: _PhoneShell(navigationShell: navigationShell, onTap: _onTap),
      // Tablet/Landscape: side NavigationRail
      tablet: _TabletShell(navigationShell: navigationShell, onTap: _onTap),
    );
  }
}

// ─── Phone layout ─────────────────────────────────────────────────────────

class _PhoneShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final ValueChanged<int> onTap;

  const _PhoneShell({required this.navigationShell, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _destinations(theme.colorScheme.primary),
      ),
    );
  }
}

// ─── Tablet/Landscape layout ───────────────────────────────────────────────

class _TabletShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final ValueChanged<int> onTap;

  const _TabletShell({required this.navigationShell, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: onTap,
            extended: MediaQuery.sizeOf(context).width >= 1024,
            backgroundColor: isDark
                ? const Color(0xFF1E293B)
                : Colors.white,
            indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            selectedIconTheme: IconThemeData(color: theme.colorScheme.primary),
            unselectedIconTheme: IconThemeData(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            selectedLabelTextStyle: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelTextStyle: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 12,
            ),
            useIndicator: true,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.space_dashboard_outlined),
                selectedIcon: Icon(Icons.space_dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: Text('History'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

// ─── Shared Navigation Rail Items ──────────────────────────────────────────

List<NavigationRailDestination> _railDestinations(Color primaryColor) {
  return [
    NavigationRailDestination(
      icon: const Icon(Icons.space_dashboard_outlined),
      selectedIcon: Icon(Icons.space_dashboard, color: primaryColor),
      label: const Text('Dashboard'),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.map_outlined),
      selectedIcon: Icon(Icons.map, color: primaryColor),
      label: const Text('History'),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings, color: primaryColor),
      label: const Text('Settings'),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.terminal_outlined),
      selectedIcon: Icon(Icons.terminal, color: primaryColor),
      label: const Text('Logs'),
    ),
  ];
}

// ─── Shared destinations ──────────────────────────────────────────────────

List<Widget> _destinations(Color primaryColor) {
  return [
    NavigationDestination(
      icon: const Icon(Icons.space_dashboard_outlined),
      selectedIcon: Icon(Icons.space_dashboard, color: primaryColor),
      label: 'Dashboard',
      tooltip: 'Dashboard',
    ),
    NavigationDestination(
      icon: const Icon(Icons.map_outlined),
      selectedIcon: Icon(Icons.map, color: primaryColor),
      label: 'History',
      tooltip: 'History',
    ),
    NavigationDestination(
      icon: const Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings, color: primaryColor),
      label: 'Settings',
      tooltip: 'Settings',
    ),
    NavigationDestination(
      icon: const Icon(Icons.terminal_outlined),
      selectedIcon: Icon(Icons.terminal, color: primaryColor),
      label: 'Logs',
      tooltip: 'Logs',
    ),
  ];
}
