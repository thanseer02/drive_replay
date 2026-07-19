import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drive_tracker/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:drive_tracker/features/settings/viewmodel/settings_viewmodel.dart';
import 'package:drive_tracker/widgets/animated_number.dart';
import 'package:drive_tracker/widgets/animated_duration.dart';
import 'package:drive_tracker/widgets/speed_gauge.dart';
import 'package:drive_tracker/widgets/shimmer_loader.dart';
import 'package:drive_tracker/widgets/adaptive_layout.dart';
import 'package:drive_tracker/services/permission_service.dart';
import 'package:drive_tracker/core/di.dart';
import 'package:drive_tracker/widgets/prominent_disclosure_dialog.dart';
import 'package:permission_handler/permission_handler.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedStartLocation = 'Home';
  String _selectedEndLocation = 'Office';

  final List<String> _locations = ['Home', 'Office', 'Gym', 'Supermarket', 'Airport', 'Coffee Shop', 'Client Office'];

  @override
  void initState() {
    super.initState();
    // Load existing stats on boot
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardViewModel>().loadDashboardStats();
    });
  }

  Future<void> _handleStartStop(BuildContext context, ThemeData theme, bool isTracking) async {
    final dashboardVM = context.read<DashboardViewModel>();
    if (isTracking) {
      final messenger = ScaffoldMessenger.of(context);
      final primaryColor = theme.colorScheme.primary;
      final savedDrive = await dashboardVM.stopTracking(
        _selectedStartLocation,
        _selectedEndLocation,
      );
      if (savedDrive != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Drive saved successfully: ${savedDrive.notes}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else {
      final permissionService = ServiceLocator.get<PermissionService>();

      var locationStatus = await permissionService.checkLocationPermission();
      var notificationStatus = await permissionService.checkNotificationPermission();

      // If permissions are not yet granted, request starting with a prominent disclosure
      if (!locationStatus.isGranted || !notificationStatus.isGranted) {
        if (!mounted) return;
        
        final acceptDisclosure = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => ProminentDisclosureDialog(
            onAccept: () => Navigator.pop(ctx, true),
            onDeny: () => Navigator.pop(ctx, false),
          ),
        );

        if (acceptDisclosure == true) {
          locationStatus = await permissionService.requestLocationPermission();
          notificationStatus = await permissionService.requestNotificationPermission();

          // On Android 10+ (Q+), ask for ACCESS_BACKGROUND_LOCATION if foreground location is granted
          if (locationStatus.isGranted) {
            await permissionService.requestBackgroundLocationPermission();
          }
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location tracking requires access to GPS coordinates.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }

      if (locationStatus.isGranted) {
        dashboardVM.startTracking();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location permissions denied. Please enable them in app settings.'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => permissionService.openAppSettingsPage(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Widget phoneBody = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // Speed gauge or Welcome vehicle overview card
          Selector<DashboardViewModel, bool>(
            selector: (_, vm) => vm.isTracking,
            builder: (context, isTracking, _) {
              if (isTracking) {
                return Selector2<DashboardViewModel, SettingsViewModel, double>(
                  selector: (_, vmDash, vmSet) => vmDash.currentSpeed * (vmSet.useMetric ? 1.0 : 0.621371),
                  builder: (context, displayCurrentSpeed, _) {
                    final useMetric = context.read<SettingsViewModel>().useMetric;
                    return SpeedGauge(
                      speed: displayCurrentSpeed,
                      maxSpeed: useMetric ? 160.0 : 100.0,
                      unit: useMetric ? 'km/h' : 'mph',
                    );
                  },
                );
              } else {
                return _buildWelcomeCard(theme);
              }
            },
          ),

          const SizedBox(height: 32),

          // Telemetry Stats grid (Garmin/Google Fit styled compact grid)
          _buildStatsGrid(theme),

          const SizedBox(height: 32),

          // Location selectors (only shown when idling)
          Selector<DashboardViewModel, bool>(
            selector: (_, vm) => vm.isTracking,
            builder: (context, isTracking, _) {
              if (!isTracking) {
                return _buildLocationSelectors(theme);
              }
              return const SizedBox.shrink();
            },
          ),

          const SizedBox(height: 24),

          // Large Premium Action Button
          Selector<DashboardViewModel, bool>(
            selector: (_, vm) => vm.isTracking,
            builder: (context, isTracking, _) {
              return _StartStopButton(
                isTracking: isTracking,
                onPressed: () => _handleStartStop(context, theme, isTracking),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );

    final Widget tabletBody = TwoColumnLayout(
      showDivider: false,
      leftFlex: 1.0,
      rightFlex: 1.0,
      left: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Selector<DashboardViewModel, bool>(
              selector: (_, vm) => vm.isTracking,
              builder: (context, isTracking, _) {
                if (isTracking) {
                  return Selector2<DashboardViewModel, SettingsViewModel, double>(
                    selector: (_, vmDash, vmSet) => vmDash.currentSpeed * (vmSet.useMetric ? 1.0 : 0.621371),
                    builder: (context, displayCurrentSpeed, _) {
                      final useMetric = context.read<SettingsViewModel>().useMetric;
                      return SpeedGauge(
                        speed: displayCurrentSpeed,
                        maxSpeed: useMetric ? 160.0 : 100.0,
                        unit: useMetric ? 'km/h' : 'mph',
                      );
                    },
                  );
                } else {
                  return _buildWelcomeCard(theme);
                }
              },
            ),
            const SizedBox(height: 16),
            Selector<DashboardViewModel, bool>(
              selector: (_, vm) => vm.isTracking,
              builder: (context, isTracking, _) {
                if (!isTracking) {
                  return _buildLocationSelectors(theme);
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 24),
            Selector<DashboardViewModel, bool>(
              selector: (_, vm) => vm.isTracking,
              builder: (context, isTracking, _) {
                return _StartStopButton(
                  isTracking: isTracking,
                  onPressed: () => _handleStartStop(context, theme, isTracking),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      right: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              'TELEMETRY DATA LOGS',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatsGrid(theme),
            const SizedBox(height: 24),
          ],
        ),
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
            children: [
              // Premium Header Area (Tesla style)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DRIVE TRACKER',
                          style: theme.textTheme.labelMedium?.copyWith(
                            letterSpacing: 3,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Selector<DashboardViewModel, bool>(
                          selector: (_, vm) => vm.isTracking,
                          builder: (context, isTracking, _) {
                            return Text(
                              isTracking ? 'Active Log' : 'Status: Ready',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Selector<DashboardViewModel, bool>(
                      selector: (_, vm) => vm.isTracking,
                      builder: (context, isTracking, _) {
                        if (!isTracking) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'REC',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              )
                            ],
                          ),
                        );
                      },
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


  // Welcome widget with Tesla vehicle styling
  Widget _buildWelcomeCard(ThemeData theme) {
    final bool isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_car_rounded,
                size: 72,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Start a New Drive Log',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Select your travel route below and tap start to begin capturing telemetry variables.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Location configuration selectors
  Widget _buildLocationSelectors(ThemeData theme) {
    final bool isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ROUTE SETUP MOCK',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start Point', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      DropdownButton<String>(
                        value: _selectedStartLocation,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: _locations.map((loc) {
                          return DropdownMenuItem(value: loc, child: Text(loc));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedStartLocation = val);
                        },
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Icon(Icons.arrow_forward_rounded, color: Colors.grey),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('End Point', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      DropdownButton<String>(
                        value: _selectedEndLocation,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: _locations.map((loc) {
                          return DropdownMenuItem(value: loc, child: Text(loc));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedEndLocation = val);
                        },
                      ),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Telemetry Grid layouts (Garmin styled split values cards)
  Widget _buildStatsGrid(ThemeData theme) {
    final dashboardVM = context.watch<DashboardViewModel>();
    final bool isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final strokeColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    if (dashboardVM.isLoading) {
      return Column(
        children: [
          Row(
            children: const [
              Expanded(child: ShimmerStatTile()),
              SizedBox(width: 12),
              Expanded(child: ShimmerStatTile()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: ShimmerStatTile()),
              SizedBox(width: 12),
              Expanded(child: ShimmerStatTile()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: ShimmerStatTile()),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(

          children: [
            Expanded(
              child: Selector2<DashboardViewModel, SettingsViewModel, double>(
                selector: (_, vmDash, vmSet) => vmDash.activeDistance * (vmSet.useMetric ? 1.0 : 0.621371),
                builder: (context, displayDistance, _) {
                  final useMetric = context.read<SettingsViewModel>().useMetric;
                  return _buildMetricTile(
                    theme: theme,
                    title: 'DISTANCE',
                    value: displayDistance,
                    suffix: useMetric ? ' km' : ' mi',
                    icon: Icons.map_rounded,
                    iconColor: Colors.blueAccent,
                    cardBg: cardBg,
                    strokeColor: strokeColor,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Selector2<DashboardViewModel, SettingsViewModel, double>(
                selector: (_, vmDash, vmSet) => vmDash.maxSpeed * (vmSet.useMetric ? 1.0 : 0.621371),
                builder: (context, displayMaxSpeed, _) {
                  final useMetric = context.read<SettingsViewModel>().useMetric;
                  return _buildMetricTile(
                    theme: theme,
                    title: 'MAX SPEED',
                    value: displayMaxSpeed,
                    suffix: useMetric ? ' km/h' : ' mph',
                    icon: Icons.speed_rounded,
                    iconColor: Colors.indigoAccent,
                    cardBg: cardBg,
                    strokeColor: strokeColor,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Selector<DashboardViewModel, int>(
                selector: (_, vm) => vm.drivingTimeSeconds,
                builder: (context, seconds, _) {
                  return _buildTimerTile(
                    theme: theme,
                    title: 'DRIVING TIME',
                    seconds: seconds,
                    icon: Icons.timer_rounded,
                    iconColor: const Color(0xFF10B981),
                    cardBg: cardBg,
                    strokeColor: strokeColor,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Selector<DashboardViewModel, int>(
                selector: (_, vm) => vm.stoppedTimeSeconds,
                builder: (context, seconds, _) {
                  return _buildTimerTile(
                    theme: theme,
                    title: 'STOPPED TIME',
                    seconds: seconds,
                    icon: Icons.pause_circle_filled_rounded,
                    iconColor: Colors.orangeAccent,
                    cardBg: cardBg,
                    strokeColor: strokeColor,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Selector2<DashboardViewModel, SettingsViewModel, double>(
                selector: (_, vmDash, vmSet) => vmDash.averageSpeed * (vmSet.useMetric ? 1.0 : 0.621371),
                builder: (context, displayAvgSpeed, _) {
                  final useMetric = context.read<SettingsViewModel>().useMetric;
                  return _buildMetricTile(
                    theme: theme,
                    title: 'AVERAGE SPEED',
                    value: displayAvgSpeed,
                    suffix: useMetric ? ' km/h' : ' mph',
                    icon: Icons.query_stats_rounded,
                    iconColor: Colors.tealAccent,
                    cardBg: cardBg,
                    strokeColor: strokeColor,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required ThemeData theme,
    required String title,
    required double value,
    required String suffix,
    required IconData icon,
    required Color iconColor,
    required Color cardBg,
    required Color strokeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: strokeColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  letterSpacing: 1.0,
                ),
              ),
              Icon(icon, color: iconColor, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedNumber(
            value: value,
            precision: 1,
            suffix: suffix,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerTile({
    required ThemeData theme,
    required String title,
    required int seconds,
    required IconData icon,
    required Color iconColor,
    required Color cardBg,
    required Color strokeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: strokeColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  letterSpacing: 1.0,
                ),
              ),
              Icon(icon, color: iconColor, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedDuration(
            seconds: seconds,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// Glowing pulsating active Start/Stop controller button widget style
class _StartStopButton extends StatefulWidget {
  final bool isTracking;
  final VoidCallback onPressed;

  const _StartStopButton({
    required this.isTracking,
    required this.onPressed,
  });

  @override
  State<_StartStopButton> createState() => _StartStopButtonState();
}

class _StartStopButtonState extends State<_StartStopButton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isTracking) {
      _animController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _StartStopButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTracking) {
      if (!_animController.isAnimating) {
        _animController.repeat(reverse: true);
      }
    } else {
      _animController.stop();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color buttonColor = widget.isTracking ? Colors.redAccent : theme.colorScheme.primary;
    final Color secondaryColor = widget.isTracking ? Colors.orangeAccent : theme.colorScheme.secondary;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: widget.isTracking
                ? [
                    BoxShadow(
                      color: buttonColor.withOpacity(0.3),
                      blurRadius: 20 * _pulseAnimation.value,
                      spreadRadius: 4 * _pulseAnimation.value,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: buttonColor.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
          ),
          child: GestureDetector(
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [buttonColor, secondaryColor],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.isTracking ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.isTracking ? 'STOP' : 'START',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

