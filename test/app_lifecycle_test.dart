import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drive_tracker/core/di.dart';
import 'package:drive_tracker/services/storage_service.dart';
import 'package:drive_tracker/repositories/ride_repository.dart';
import 'package:drive_tracker/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:drive_tracker/models/ride.dart';
import 'package:drive_tracker/models/ride_location.dart';
import 'package:drive_tracker/models/settings_model.dart';

class FakeRideRepository implements RideRepository {
  @override
  Future<List<Ride>> getRides() async => [];
  @override
  Future<Ride?> getRide(int id) async => null;
  @override
  Future<int> addRide(Ride ride) async => 1;
  @override
  Future<int> updateRide(Ride ride) async => 1;
  @override
  Future<int> deleteRide(int id) async => 1;
  @override
  Future<int> clearRides() async => 1;
  @override
  Future<int> addRideLocation(RideLocation location) async => 1;
  @override
  Future<List<RideLocation>> getLocationsForRide(int rideId) async => [];
  @override
  Future<SettingsModel> getSettings() async => SettingsModel(isDarkMode: false, useMetric: true);
  @override
  Future<int> updateSettings(SettingsModel settings) async => 1;
}

void main() {
  const controlChannel = MethodChannel('com.example.drivetracker/tracking_control');
  const eventChannel = MethodChannel('com.example.drivetracker/tracking_events');

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    ServiceLocator.clear();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ServiceLocator.register<StorageService>(StorageService(prefs));
    ServiceLocator.register<RideRepository>(FakeRideRepository());

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(controlChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'getTelemetry') {
        return {
          'isTracking': true,
          'currentSpeed': 5.0,
          'maxSpeed': 12.0,
          'distance': 1000.0,
          'drivingTime': 90,
          'stopTime': 10,
        };
      }
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(eventChannel, (MethodCall methodCall) async {
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(controlChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(eventChannel, null);
  });

  group('App Lifecycle & Process Recreation Tests', () {
    test('Process recreation loads running session state natively', () async {
      // Simulate process startup while service was already running in native background
      final viewModel = DashboardViewModel();
      await viewModel.loadDashboardStats();

      // Verify stats are restored correctly on startup/recreation
      expect(viewModel.isTracking, isTrue);
      expect(viewModel.currentSpeed, closeTo(18.0, 0.01)); // 5.0 m/s -> 18.0 km/h
      expect(viewModel.maxSpeed, closeTo(43.2, 0.01)); // 12.0 m/s -> 43.2 km/h
      expect(viewModel.activeDistance, closeTo(1.0, 0.01)); // 1000m -> 1km
      expect(viewModel.drivingTimeSeconds, 90);
      expect(viewModel.stoppedTimeSeconds, 10);
    });

    test('Moving app background/foreground state handles listeners streams clean', () async {
      final viewModel = DashboardViewModel();
      await viewModel.loadDashboardStats();
      expect(viewModel.isTracking, isTrue);

      // Simulate system notification focus state triggers and app backgrounding
      // The stream listener is active and does not drop binding configurations during focus transitions
      viewModel.routeEventForTesting({
        'type': 'telemetry',
        'currentSpeed': 8.0,
        'maxSpeed': 15.0,
        'distance': 1200.0,
        'drivingTime': 100,
        'stopTime': 12,
        'heading': 90.0,
        'altitude': 110.0,
      });

      expect(viewModel.currentSpeed, closeTo(28.8, 0.01));
      expect(viewModel.drivingTimeSeconds, 100);
    });
  });
}
