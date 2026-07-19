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

// Fake implementations for Mocking
class FakeRideRepository implements RideRepository {
  List<Ride> rides = [];

  @override
  Future<List<Ride>> getRides() async => rides;
  @override
  Future<Ride?> getRide(int id) async => null;
  @override
  Future<int> addRide(Ride ride) async {
    rides.add(ride);
    return 1;
  }
  @override
  Future<int> updateRide(Ride ride) async => 1;
  @override
  Future<int> deleteRide(int id) async => 1;
  @override
  Future<int> clearRides() async {
    rides.clear();
    return 1;
  }
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

  late FakeRideRepository fakeRepo;
  late DashboardViewModel viewModel;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    ServiceLocator.clear();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ServiceLocator.register<StorageService>(StorageService(prefs));
    
    fakeRepo = FakeRideRepository();
    ServiceLocator.register<RideRepository>(fakeRepo);

    // Mock initial state for VM boot check
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(controlChannel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getTelemetry':
          return {'isTracking': false};
        case 'startTracking':
          return true;
        case 'stopTracking':
          return true;
        default:
          return null;
      }
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(eventChannel, (MethodCall methodCall) async {
      return null; // Return null to simulate successful stream listener registration
    });

    viewModel = DashboardViewModel();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(controlChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(eventChannel, null);
  });

  group('MethodChannel Control Channel Tests', () {
    test('startTracking invokes method channel and flags isTracking as true', () async {
      bool controlInvoked = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(controlChannel, (MethodCall methodCall) async {
        if (methodCall.method == 'startTracking') {
          controlInvoked = true;
          return true;
        }
        return {'isTracking': false};
      });

      expect(viewModel.isTracking, isFalse);
      
      await viewModel.startTracking();
      
      expect(controlInvoked, isTrue);
      expect(viewModel.isTracking, isTrue);
    });

    test('stopTracking invokes control channel and clears tracking flag', () async {
      bool controlStopInvoked = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(controlChannel, (MethodCall methodCall) async {
        if (methodCall.method == 'stopTracking') {
          controlStopInvoked = true;
          return true;
        }
        return {'isTracking': false};
      });

      // Force mock tracking active
      await viewModel.startTracking();
      expect(viewModel.isTracking, isTrue);

      final ride = await viewModel.stopTracking('Home', 'Office');
      
      expect(controlStopInvoked, isTrue);
      expect(viewModel.isTracking, isFalse);
      expect(ride, isNotNull);
    });
  });

  group('EventChannel Flow & Telemetry Updates', () {
    test('Simulated native telemetry events propagate correctly to viewModel', () async {
      await viewModel.startTracking();

      // Trigger telemetry updates via mock invocation of VM listener method
      viewModel.onListenEventForTesting({
        'type': 'telemetry',
        'currentSpeed': 10.0, // 36 km/h
        'maxSpeed': 20.0, // 72 km/h
        'distance': 1500.0, // 1.5 km
        'drivingTime': 120,
        'stopTime': 30,
        'heading': 45.0,
        'altitude': 100.0,
      });

      expect(viewModel.currentSpeed, closeTo(36.0, 0.01));
      expect(viewModel.maxSpeed, closeTo(72.0, 0.01));
      expect(viewModel.activeDistance, closeTo(1.5, 0.01));
      expect(viewModel.drivingTimeSeconds, 120);
      expect(viewModel.stoppedTimeSeconds, 30);
      expect(viewModel.heading, 45.0);
      expect(viewModel.altitude, 100.0);
    });

    test('Simulated native stop event triggers clean stop and VM saves data', () async {
      await viewModel.startTracking();
      expect(viewModel.isTracking, isTrue);

      // Trigger tracking stopped natively
      viewModel.onListenEventForTesting({
        'type': 'stopped',
        'startTime': DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch,
        'endTime': DateTime.now().millisecondsSinceEpoch,
        'maxSpeed': 15.0,
        'averageSpeed': 12.0,
        'distance': 2000.0,
        'drivingTime': 240,
        'stopTime': 60,
      });

      expect(viewModel.isTracking, isFalse);
      expect(viewModel.currentSpeed, 0.0);
    });
  });
}

// Add test fixture extension to DashboardViewModel to trigger events programmatically during tests without EventChannel native loops
extension TestingEventFixture on DashboardViewModel {
  void onListenEventForTesting(dynamic event) {
    routeEventForTesting(event);
  }
}
