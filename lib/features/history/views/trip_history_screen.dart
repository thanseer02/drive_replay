import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:drive_replay/core/di/dependency_injection.dart';
import 'package:drive_replay/core/theme/app_colors.dart';
import 'package:drive_replay/features/history/viewmodels/trip_history_viewmodel.dart';
import 'package:drive_replay/core/services/local_db/app_database.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  TripHistoryViewModel? _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = locator<TripHistoryViewModel>();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_viewModel == null) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _viewModel!.fetchNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final vm = locator<TripHistoryViewModel>();
        _viewModel = vm;
        return vm;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(),
              _buildStatsHeader(),
              _buildTripList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: AppColors.surface,
      title: const Text('Trip History', style: TextStyle(fontWeight: FontWeight.bold)),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search locations...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  // Debouncing would be ideal here in a real production app
                  _viewModel?.setSearchQuery(val);
                },
              ),
            ),
            Consumer<TripHistoryViewModel>(
              builder: (context, vm, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Favorites Only'),
                        selected: vm.favoritesOnly,
                        onSelected: (_) => vm.toggleFavoritesFilter(),
                        selectedColor: AppColors.primary.withValues(alpha: 0.3),
                        checkmarkColor: AppColors.primary,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    return SliverToBoxAdapter(
      child: Consumer<TripHistoryViewModel>(
        builder: (context, vm, child) {
          if (vm.trips.isEmpty && !vm.isLoading) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatCard(title: 'Trips', value: '${vm.totalTripsCount}'),
                _StatCard(title: 'Total Dist', value: '${(vm.totalDistance / 1000).toStringAsFixed(1)} km'),
              ],
            ).animate().fadeIn().slideY(begin: 0.2),
          );
        },
      ),
    );
  }

  Widget _buildTripList() {
    return Consumer<TripHistoryViewModel>(
      builder: (context, vm, child) {
        if (vm.trips.isEmpty && vm.isLoading) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (vm.trips.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car, size: 64, color: AppColors.secondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('No trips found', style: TextStyle(fontSize: 18, color: AppColors.onBackground)),
                ],
              ),
            ).animate().fadeIn(),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == vm.trips.length) {
                if (!vm.hasMore) return const SizedBox();
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final trip = vm.trips[index];
              return _TripCard(trip: trip, viewModel: vm)
                .animate(delay: Duration(milliseconds: 50 * (index % 10)))
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.1, duration: 300.ms);
            },
            childCount: !vm.hasMore ? vm.trips.length : vm.trips.length + 1,
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
        Text(title, style: const TextStyle(fontSize: 12, color: AppColors.onSurface)),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final TripHistoryViewModel viewModel;

  const _TripCard({required this.trip, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(trip.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        await viewModel.deleteTrip(trip.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Trip deleted'),
              action: SnackBarAction(
                label: 'UNDO',
                onPressed: () => viewModel.restoreTrip(trip.id),
              ),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trip #${trip.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          trip.isFavorite ? Icons.star : Icons.star_border,
                          color: trip.isFavorite ? Colors.amber : Colors.grey,
                        ),
                        onPressed: () => viewModel.toggleFavorite(trip.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.download, color: AppColors.primary),
                        onPressed: () async {
                          final path = await viewModel.exportTrip(trip.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to $path')));
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('${trip.startTime.toLocal()}'.split('.')[0]),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Distance', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('${(trip.totalDistance / 1000).toStringAsFixed(2)} km', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
