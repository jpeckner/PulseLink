import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pulselink/domain/bluetooth_problem.dart';
import 'package:pulselink/ui/widgets/problem_view.dart';

import '../helpers/stub_app_settings.dart';

const _couldNotOpen =
    "Couldn't open Settings. Open the Settings app, then find PulseLink there.";

void main() {
  group('ProblemView', () {
    late StubAppSettings settings;

    setUp(() => settings = StubAppSettings());

    Future<void> pumpView(
      WidgetTester tester,
      BluetoothProblem problem, {
      VoidCallback? onTryAgain,
    }) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProblemView(
            message: bluetoothProblemMessage(problem),
            appSettings: settings,
            onTryAgain: onTryAgain,
          ),
        ),
      ),
    );

    test('only denied permission is fixed in settings', () {
      for (final problem in BluetoothProblem.values) {
        final isFixedInSettings = switch (problem) {
          BluetoothProblem.permissionDenied => true,
          BluetoothProblem.off || BluetoothProblem.unavailable => false,
        };
        expect(
          bluetoothProblemMessage(problem).isFixedInSettings,
          isFixedInSettings,
          reason: problem.name,
        );
      }
    });

    testWidgets('Open Settings is the main button, before Try again', (
      tester,
    ) async {
      await pumpView(tester, .permissionDenied, onTryAgain: () {});
      final openSettings = find.widgetWithText(FilledButton, 'Open Settings');
      final tryAgain = find.widgetWithText(OutlinedButton, 'Try again');
      expect(openSettings, findsOneWidget);
      expect(tryAgain, findsOneWidget);
      expect(
        tester.getTopLeft(openSettings).dy,
        lessThan(tester.getTopLeft(tryAgain).dy),
      );
    });

    testWidgets('Try again is the main button without Open Settings', (
      tester,
    ) async {
      await pumpView(tester, .off, onTryAgain: () {});
      expect(find.text('Open Settings'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);
    });

    testWidgets('opening Settings says nothing when it opens', (tester) async {
      await pumpView(tester, .permissionDenied);
      await tester.tap(find.text('Open Settings'));
      await tester.pump();
      expect(settings.openCount, 1);
      expect(find.text(_couldNotOpen), findsNothing);
    });

    testWidgets("says so when Settings doesn't open", (tester) async {
      settings.opens = false;
      await pumpView(tester, .permissionDenied);
      await tester.tap(find.text('Open Settings'));
      await tester.pump();
      expect(settings.openCount, 1);
      expect(find.text(_couldNotOpen), findsOneWidget);
    });

    testWidgets('says so even if the view is gone when Settings answers', (
      tester,
    ) async {
      settings.opens = false;
      await pumpView(tester, .permissionDenied);
      await tester.tap(find.text('Open Settings'));
      // Replace the view before the open completes; the snack bar still goes
      // to the app's messenger.
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('elsewhere'))),
      );
      await tester.pump();
      expect(find.text(_couldNotOpen), findsOneWidget);
    });
  });
}
