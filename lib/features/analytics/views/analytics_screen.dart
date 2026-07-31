import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:drive_replay/core/di/dependency_injection.dart';
import 'package:drive_replay/core/theme/app_colors.dart';
import 'package:drive_replay/features/analytics/viewmodels/analytics_viewmodel.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final AnalyticsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = locator<AnalyticsViewModel>();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        body: Consumer<AnalyticsViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return CustomScrollView(
              slivers: [
                _buildTimeRangeSelector(vm),
                _buildHeroStats(vm),
                _buildDistanceChart(vm),
                _buildIdleChart(vm),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector(AnalyticsViewModel vm) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SegmentedButton<TimeRange>(
          segments: const [
            ButtonSegment(value: TimeRange.weekly, label: Text('Weekly')),
            ButtonSegment(value: TimeRange.monthly, label: Text('Monthly')),
            ButtonSegment(value: TimeRange.yearly, label: Text('Yearly')),
          ],
          selected: {vm.currentRange},
          onSelectionChanged: (Set<TimeRange> newSelection) {
            vm.setTimeRange(newSelection.first);
          },
        ),
      ),
    );
  }

  Widget _buildHeroStats(AnalyticsViewModel vm) {
    final stats = vm.stats;
    if (stats == null) return const SliverToBoxAdapter(child: SizedBox());

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.5,
        children: [
          _StatCard(
            title: 'Total Distance',
            value: '${(stats.totalDistance / 1000).toStringAsFixed(1)} km',
            icon: Icons.route,
            color: Colors.blueAccent,
          ),
          _StatCard(
            title: 'Driving Time',
            value: '${stats.totalTripDuration.inHours}h ${stats.totalTripDuration.inMinutes.remainder(60)}m',
            icon: Icons.timer,
            color: Colors.greenAccent,
          ),
          _StatCard(
            title: 'Avg Speed',
            value: '${(stats.averageSpeed * 3.6).toStringAsFixed(1)} km/h',
            icon: Icons.speed,
            color: Colors.orangeAccent,
          ),
          _StatCard(
            title: 'Max Speed',
            value: '${(stats.maxSpeed * 3.6).toStringAsFixed(1)} km/h',
            icon: Icons.flash_on,
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceChart(AnalyticsViewModel vm) {
    return SliverToBoxAdapter(
      child: Container(
        height: 300,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Distance Trend (km)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 24),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: vm.maxChartY,
                  barTouchData: const BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          // Placeholder logic: in production, map value (index) to actual date strings
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('${value.toInt()}', style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: vm.chartData,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleChart(AnalyticsViewModel vm) {
    final stats = vm.stats;
    if (stats == null || (stats.totalTripDuration.inSeconds == 0)) {
      return const SliverToBoxAdapter(child: SizedBox());
    }

    final drivingMs = stats.totalTripDuration.inMilliseconds - stats.totalIdleTime.inMilliseconds;
    final idleMs = stats.totalIdleTime.inMilliseconds;

    return SliverToBoxAdapter(
      child: Container(
        height: 250,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: Colors.greenAccent,
                      value: drivingMs.toDouble(),
                      title: 'Driving',
                      radius: 20,
                      titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    PieChartSectionData(
                      color: Colors.redAccent,
                      value: idleMs.toDouble(),
                      title: 'Idle',
                      radius: 20,
                      titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Time Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  _buildLegendIndicator(Colors.greenAccent, 'Driving (${stats.totalTripDuration.inHours}h)'),
                  const SizedBox(height: 8),
                  _buildLegendIndicator(Colors.redAccent, 'Idle (${stats.totalIdleTime.inMinutes}m)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendIndicator(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12))),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}
