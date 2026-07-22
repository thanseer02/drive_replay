import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drive_tracker/core/di.dart';
import 'package:drive_tracker/services/storage_service.dart';
import 'package:drive_tracker/services/permission_service.dart';
import 'package:drive_tracker/models/activity_model.dart';
import 'package:drive_tracker/repositories/activity_repository.dart';
import 'package:drive_tracker/features/settings/viewmodel/settings_viewmodel.dart';
import 'package:drive_tracker/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:drive_tracker/features/history/viewmodel/history_viewmodel.dart';
import 'package:drive_tracker/features/splash/splash_screen.dart';
import 'package:drive_tracker/features/dashboard/presentation/dashboard_screen.dart';
import 'package:drive_tracker/features/settings/presentation/settings_screen.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

// Fake implementations for Mocking
class FakeActivityRepository implements ActivityRepository {
  @override
  Future<List<ActivityModel>> getActivities() async => [];
  @override
  Future<ActivityModel?> getActivityDetails(int id) async => null;
  @override
  Future<void> addActivity(ActivityModel activity) async {}
  @override
  Future<void> deleteActivity(int id) async {}
  @override
  Future<void> clearActivities() async {}
}

class FakePermissionService extends PermissionService {
  @override
  Future<PermissionStatus> checkLocationPermission() async => PermissionStatus.granted;
  @override
  Future<PermissionStatus> checkNotificationPermission() async => PermissionStatus.granted;
}

void main() {
  const controlChannel = MethodChannel('com.example.drivetracker/tracking_control');
  const eventChannel = MethodChannel('com.example.drivetracker/tracking_events');

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    // Reset ServiceLocator registers safely
    ServiceLocator.clear();

    // Register basic storage requirements
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ServiceLocator.register<StorageService>(StorageService(prefs));
    ServiceLocator.register<ActivityRepository>(FakeActivityRepository());
    ServiceLocator.register<PermissionService>(FakePermissionService());

    // Mock native method calls to prevent MissingPluginException
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(controlChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'getTelemetry') {
        return {'isTracking': false};
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

  Widget buildTestWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsViewModel>(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider<DashboardViewModel>(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider<HistoryViewModel>(create: (_) => HistoryViewModel()),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('Screen Widget Tests', () {
    testWidgets('SplashScreen layout structure mounts correctly', (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
          GoRoute(path: '/dashboard', builder: (context, state) => const Scaffold(body: Text('Dashboard Mock'))),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      
      expect(find.text('Drive Tracker'), findsOneWidget);
      expect(find.text('Your smart commuting companion'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Dashboard Mock'), findsOneWidget);
    });

    testWidgets('DashboardScreen renders elements correctly when idle', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(const DashboardScreen()));
      await tester.pumpAndSettle();

      // Check stats cards are rendered
      expect(find.text('DRIVE TRACKER'), findsOneWidget);
      expect(find.text('START'), findsOneWidget);
      expect(find.text('DISTANCE'), findsOneWidget);
    });

    testWidgets('SettingsScreen displays preference elements', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.text('Use Metric Units'), findsOneWidget);
    });
  });
}
