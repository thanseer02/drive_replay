import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:drive_replay/core/theme/app_colors.dart';
import 'package:drive_replay/bootstrap/bootstrap_viewmodel.dart';
import 'package:drive_replay/bootstrap/app_bootstrap.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final BootstrapViewModel _viewModel;
  late final AppBootstrap _bootstrap;

  @override
  void initState() {
    super.initState();
    _viewModel = BootstrapViewModel();
    _bootstrap = AppBootstrap(_viewModel);
    
    // Listen for success state to navigate away
    _viewModel.addListener(_onStateChange);
    
    // Start engine
    _bootstrap.runInitialization();
  }

  void _onStateChange() {
    if (_viewModel.state == BootstrapState.success) {
      _viewModel.removeListener(_onStateChange);
      
      // Delay slightly for visual polish
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Consumer<BootstrapViewModel>(
            builder: (context, vm, child) {
              if (vm.state == BootstrapState.error) {
                return _buildErrorState(vm);
              }
              return _buildLoadingState(vm);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BootstrapViewModel vm) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.directions_car, size: 80, color: AppColors.primary)
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.1, duration: 1.seconds)
          .shimmer(duration: 2.seconds),
          
        const SizedBox(height: 32),
        
        const Text(
          'Drive Replay',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.5, end: 0.0),
        
        const SizedBox(height: 8),
        
        const Text('v1.0.0 (Production)', style: TextStyle(color: Colors.white54)),
        
        const SizedBox(height: 48),
        
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            backgroundColor: Colors.white12,
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        
        const SizedBox(height: 16),
        
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            vm.currentStep,
            key: ValueKey(vm.currentStep),
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BootstrapViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 24),
          const Text(
            'Initialization Failed',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            vm.errorMessage ?? 'Unknown error occurred.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              vm.reset();
              _bootstrap.runInitialization();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
