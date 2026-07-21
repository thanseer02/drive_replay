import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:drive_tracker/features/history/viewmodel/history_viewmodel.dart';
import 'package:drive_tracker/features/settings/viewmodel/settings_viewmodel.dart';
import 'package:drive_tracker/models/ride.dart';
import 'package:drive_tracker/widgets/shimmer_loader.dart';
import 'package:drive_tracker/widgets/error_view.dart';
import 'package:drive_tracker/widgets/empty_state_view.dart';
import 'package:drive_tracker/widgets/adaptive_layout.dart';
import 'package:drive_tracker/features/history/presentation/ride_details_screen.dart';
import 'package:drive_tracker/themes/app_text_styles.dart';


class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedRideId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryViewModel>().loadDrives();
    });
    _searchController.addListener(() {
      context.read<HistoryViewModel>().setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final historyVM = context.watch<HistoryViewModel>();
    final settingsVM = context.watch<SettingsViewModel>();

    final bool useMetric = settingsVM.useMetric;
    final double distMulti = useMetric ? 1.0 : 0.621371;
    final String velocityUnit = useMetric ? 'km/h' : 'mph';
    final String distLabel = useMetric ? 'km' : 'mi';

    final Widget phoneBody = Column(
      children: [
        _buildSearchAndFiltersHeader(context, theme, historyVM),
        Expanded(
          child: historyVM.isLoading
              ? const ShimmerHistoryList()
              : historyVM.error != null
                  ? AppErrorView(
                      message: historyVM.error!,
                      onRetry: historyVM.loadDrives,
                    )
                  : historyVM.filteredDrives.isEmpty
                      ? AppEmptyView(
                          icon: historyVM.searchQuery.isNotEmpty
                              ? Icons.search_off_rounded
                              : Icons.history_toggle_off_rounded,
                          message: historyVM.searchQuery.isNotEmpty
                              ? 'No Matching Rides Found'
                              : 'No Rides Recorded Yet',
                          subMessage: historyVM.searchQuery.isNotEmpty
                              ? 'Try adjusting your search or filters.'
                              : 'Start a drive from the Dashboard tab.',
                        )
                      : _buildGroupedDriveList(
                          context,
                          theme,
                          historyVM.filteredDrives,
                          distMulti,
                          distLabel,
                          velocityUnit,
                          historyVM,
                        ),
        ),
      ],
    );

    final filtered = historyVM.filteredDrives;
    if (_selectedRideId != null && !filtered.any((e) => e.id == _selectedRideId)) {
      _selectedRideId = null;
    }
    if (_selectedRideId == null && filtered.isNotEmpty) {
      _selectedRideId = filtered.first.id;
    }

    final Widget tabletBody = Column(
      children: [
        _buildSearchAndFiltersHeader(context, theme, historyVM),
        Expanded(
          child: TwoColumnLayout(
            leftFlex: 1,
            rightFlex: 1,
            showDivider: true,
            left: historyVM.isLoading
                ? const ShimmerHistoryList()
                : historyVM.error != null
                    ? AppErrorView(
                        message: historyVM.error!,
                        onRetry: historyVM.loadDrives,
                      )
                    : filtered.isEmpty
                        ? AppEmptyView(
                            icon: historyVM.searchQuery.isNotEmpty
                                ? Icons.search_off_rounded
                                : Icons.history_toggle_off_rounded,
                            message: historyVM.searchQuery.isNotEmpty
                                ? 'No Matching Rides Found'
                                : 'No Rides Recorded Yet',
                            subMessage: historyVM.searchQuery.isNotEmpty
                                ? 'Try adjusting your search or filters.'
                                : 'Start a drive from the Dashboard tab.',
                          )
                        : _buildGroupedDriveList(
                            context,
                            theme,
                            filtered,
                            distMulti,
                            distLabel,
                            velocityUnit,
                            historyVM,
                          ),
            right: _selectedRideId != null
                ? KeyedSubtree(
                    key: ValueKey(_selectedRideId),
                    child: RideDetailsScreen(
                      driveId: _selectedRideId!,
                      isEmbedded: true,
                    ),
                  )
                : Scaffold(
                    appBar: AppBar(
                      automaticallyImplyLeading: false,
                      title: const Text('Ride Details'),
                    ),
                    body: const Center(
                      child: Text(
                        'Select a ride to view metrics',
                        style: AppTextStyles.ts15w700,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride History'),
        actions: [
          if (historyVM.drives.isNotEmpty)
            Tooltip(
              message: 'Clear All Logs',
              child: IconButton(
                icon: const Icon(Icons.delete_sweep_rounded),
                onPressed: () => _confirmClearAll(context, historyVM),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.brightness == Brightness.light
                ? [const Color(0xFFF8FAFC), const Color(0xFFFFFFFF)]
                : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
          ),
        ),
        child: AdaptiveLayout(
          phone: phoneBody,
          tablet: tabletBody,
        ),
      ),
    );
  }

  // ─── Search & Filter Header ────────────────────────────────────────────────

  Widget _buildSearchAndFiltersHeader(
    BuildContext context,
    ThemeData theme,
    HistoryViewModel viewModel,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: cardBg.withValues(alpha: 0.85),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search rides by notes or date…',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24.0),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        viewModel.setSearchQuery('');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8.0),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChip(context, theme,
                    label: _getSortLabel(viewModel.sortBy),
                    icon: Icons.sort_rounded,
                    onTap: () => _showSortOptions(context, viewModel),
                    isActive: viewModel.sortBy != 'date_desc'),
                const SizedBox(width: 8.0),
                _buildChip(context, theme,
                    label: _getDistanceFilterLabel(viewModel.filterDistance),
                    icon: Icons.map_outlined,
                    onTap: () => _showDistanceFilterOptions(context, viewModel),
                    isActive: viewModel.filterDistance != 'all'),
                const SizedBox(width: 8.0),
                _buildChip(context, theme,
                    label: _getDateFilterLabel(viewModel.filterDate),
                    icon: Icons.calendar_today_rounded,
                    onTap: () => _showDateFilterOptions(context, viewModel),
                    isActive: viewModel.filterDate != 'all'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, ThemeData theme, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: isActive ? activeColor : inactiveColor,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14,
                  color: isActive ? activeColor : theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 6.0),
              Text(label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive ? activeColor : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  )),
              const SizedBox(width: 4.0),
              Icon(Icons.arrow_drop_down_rounded, size: 16,
                  color: isActive ? activeColor : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Grouped list ─────────────────────────────────────────────────────────

  Widget _buildGroupedDriveList(
    BuildContext context,
    ThemeData theme,
    List<Ride> drives,
    double distMulti,
    String distLabel,
    String speedLabel,
    HistoryViewModel viewModel,
  ) {
    final Map<String, List<Ride>> grouped = {};
    for (final drive in drives) {
      final key = _getDateHeaderString(drive.startTime);
      grouped.putIfAbsent(key, () => []).add(drive);
    }
    final keys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: keys.length,
      itemBuilder: (context, groupIndex) {
        final dateKey = keys[groupIndex];
        final driveGroup = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 12.0, bottom: 8.0),
              child: Text(
                dateKey.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            ...driveGroup.map((drive) => _buildDriveCard(
                  context, theme, drive, distMulti, distLabel, speedLabel, viewModel)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  // ─── Drive card ──────────────────────────────────────────────────────────

  Widget _buildDriveCard(
    BuildContext context,
    ThemeData theme,
    Ride drive,
    double distMulti,
    String distLabel,
    String speedLabel,
    HistoryViewModel viewModel,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final strokeColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final displayDist = drive.distance * distMulti;
    final displayAvgSpeed = drive.averageSpeed * distMulti;
    final displayMaxSpeed = drive.maxSpeed * distMulti;
    final timeRange =
        '${DateFormat('hh:mm a').format(drive.startTime)} – ${DateFormat('hh:mm a').format(drive.endTime ?? drive.startTime)}';
    final durationString = _formatSeconds(drive.durationSeconds);
    final cardDate = DateFormat('MMM d, yyyy').format(drive.startTime);

    return Dismissible(
      key: Key('drive_${drive.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        if (drive.id != null) {
          viewModel.deleteDrive(drive.id!);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Ride log deleted'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () => viewModel.addMockDrive(drive),
            ),
          ));
        }
      },
      child: Semantics(
        label: 'Ride on ${DateFormat('MMM d').format(drive.startTime)}, '
            '${drive.distance.toStringAsFixed(1)} km',
        hint: 'Double tap to view ride details',
        button: true,
        child: Hero(
          tag: 'ride_card_${drive.id}',
          flightShuttleBuilder: (_, animation, _, _, _) => FadeTransition(
            opacity: animation,
            child: Card(
              margin: EdgeInsets.zero,
              color: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: strokeColor),
              ),
            ),
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            elevation: 0,
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: strokeColor),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                if (drive.id != null) {
                  final isWide = MediaQuery.sizeOf(context).width >= 720;
                  if (isWide) {
                    setState(() {
                      _selectedRideId = drive.id;
                    });
                  } else {
                    context.push('/ride-details/${drive.id}');
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.directions_car_rounded,
                                  color: theme.colorScheme.primary, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Drive #${drive.id} · $cardDate',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          timeRange,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStat(theme, 'DISTANCE',
                            '${displayDist.toStringAsFixed(1)} $distLabel',
                            Icons.map_outlined, Colors.blueAccent),
                        _buildStat(theme, 'DURATION', durationString,
                            Icons.av_timer_rounded, const Color(0xFF10B981)),
                        _buildStat(
                            theme,
                            'AVG',
                            '${displayAvgSpeed.toStringAsFixed(0)} $speedLabel',
                            Icons.speed_rounded,
                            Colors.indigoAccent),
                        _buildStat(
                            theme,
                            'MAX',
                            '${displayMaxSpeed.toStringAsFixed(0)} $speedLabel',
                            Icons.keyboard_double_arrow_up_rounded,
                            Colors.orangeAccent),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
            Text(label,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                )),
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style: AppTextStyles.ts13w700),
      ],
    );
  }

  // ─── Bottom sheets ────────────────────────────────────────────────────────

  void _showSortOptions(BuildContext context, HistoryViewModel viewModel) {
    final options = [
      ('date_desc', 'Newest First', Icons.arrow_downward_rounded),
      ('date_asc', 'Oldest First', Icons.arrow_upward_rounded),
      ('distance_desc', 'Longest Distance', Icons.straighten_rounded),
      ('distance_asc', 'Shortest Distance', Icons.compress_rounded),
      ('speed_desc', 'Highest Speed', Icons.bolt_rounded),
      ('duration_desc', 'Longest Duration', Icons.timer_rounded),
    ];
    _showSelectionSheet(
      context,
      title: 'Sort by',
      options: options.map((o) => (o.$1, o.$2, o.$3)).toList(),
      selected: viewModel.sortBy,
      onSelect: viewModel.setSortBy,
    );
  }

  void _showDistanceFilterOptions(BuildContext context, HistoryViewModel viewModel) {
    _showSelectionSheet(
      context,
      title: 'Filter by Distance',
      options: [
        ('all', 'All Distances', Icons.all_inclusive_rounded),
        ('short', 'Short (< 1 km)', Icons.directions_walk_rounded),
        ('medium', 'Medium (1–5 km)', Icons.directions_bike_rounded),
        ('long', 'Long (> 5 km)', Icons.directions_car_rounded),
      ],
      selected: viewModel.filterDistance,
      onSelect: viewModel.setFilterDistance,
    );
  }

  void _showDateFilterOptions(BuildContext context, HistoryViewModel viewModel) {
    _showSelectionSheet(
      context,
      title: 'Filter by Date',
      options: [
        ('all', 'All Time', Icons.all_inclusive_rounded),
        ('today', 'Today', Icons.today_rounded),
        ('yesterday', 'Yesterday', Icons.history_rounded),
        ('week', 'Last 7 Days', Icons.date_range_rounded),
      ],
      selected: viewModel.filterDate,
      onSelect: viewModel.setFilterDate,
    );
  }

  void _showSelectionSheet(
    BuildContext context, {
    required String title,
    required List<(String, String, IconData)> options,
    required String selected,
    required void Function(String) onSelect,
  }) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...options.map((opt) {
                final isSelected = opt.$1 == selected;
                return ListTile(
                  leading: Icon(opt.$3,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  title: Text(opt.$2,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? theme.colorScheme.primary : null,
                      )),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    onSelect(opt.$1);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context, HistoryViewModel viewModel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All?'),
        content: const Text('This will permanently delete all ride history.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              viewModel.clearHistory();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _getDateHeaderString(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rideDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(rideDay).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(dt);
    return DateFormat('MMMM d, yyyy').format(dt);
  }

  String _formatSeconds(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'date_asc': return 'Oldest First';
      case 'distance_desc': return 'Longest';
      case 'distance_asc': return 'Shortest';
      case 'speed_desc': return 'Fastest';
      case 'duration_desc': return 'Longest Dur.';
      default: return 'Newest First';
    }
  }

  String _getDistanceFilterLabel(String filter) {
    switch (filter) {
      case 'short': return '< 1 km';
      case 'medium': return '1–5 km';
      case 'long': return '> 5 km';
      default: return 'All Dist.';
    }
  }

  String _getDateFilterLabel(String filter) {
    switch (filter) {
      case 'today': return 'Today';
      case 'yesterday': return 'Yesterday';
      case 'week': return 'Last 7 Days';
      default: return 'All Time';
    }
  }
}
