import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drive_tracker/widgets/prominent_disclosure_dialog.dart';

void main() {
  group('Permission Prominent Disclosure Dialog Tests', () {
    testWidgets('Renders all disclosure text and handles callbacks', (WidgetTester tester) async {
      bool acceptCalled = false;
      bool denyCalled = false;

      // Pump Dialog wrapper inside MaterialApp configuration
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => ProminentDisclosureDialog(
                        onAccept: () {
                          acceptCalled = true;
                          Navigator.pop(ctx);
                        },
                        onDeny: () {
                          denyCalled = true;
                          Navigator.pop(ctx);
                        },
                      ),
                    );
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      // 1. Show the dialog
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // 2. Verify dialog components are on-screen
      expect(find.text('Background Location Access'), findsOneWidget);
      expect(find.textContaining('collects location data'), findsOneWidget);
      expect(find.text('No thanks'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);

      // 3. Tap Deny button and verify callback runs
      await tester.tap(find.text('No thanks'));
      await tester.pumpAndSettle();

      expect(denyCalled, isTrue);
      expect(acceptCalled, isFalse);
      expect(find.text('Background Location Access'), findsNothing);

      // Re-show for accept verification
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Tap Accept button and verify callback runs
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      expect(acceptCalled, isTrue);
      expect(find.text('Background Location Access'), findsNothing);
    });
  });
}
