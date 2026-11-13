import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pulselink/data/strap_scanner.dart';
import 'package:pulselink/domain/bluetooth_problem.dart';
import 'package:pulselink/ui/picker/strap_picker_screen.dart';
import 'package:pulselink/ui/widgets/disclaimer_banner.dart';

import '../helpers/discovered_strap.dart';
import '../helpers/stub_strap_scanner.dart';

void main() {
  group('StrapPickerScreen', () {
    late StubStrapScanner scanner;

    setUp(() => scanner = StubStrapScanner());

    Future<void> pumpScreen(WidgetTester tester) => tester.pumpWidget(
      MaterialApp(home: StrapPickerScreen(scanner: scanner)),
    );

    testWidgets('scans while open, and says it is looking', (tester) async {
      await pumpScreen(tester);
      expect(scanner.isScanning, isTrue);
      expect(find.text('Find your strap'), findsOneWidget);
      expect(find.text('Looking for heart-rate straps…'), findsOneWidget);
      expect(find.text(disclaimerText), findsOneWidget);
    });

    testWidgets('lists the straps it finds, naming unnamed ones', (
      tester,
    ) async {
      await pumpScreen(tester);
      scanner
        ..emit(.found(discoveredStrapOf('polar', 'Polar H10')))
        ..emit(.found(discoveredStrapOf('other')));
      await tester.pump();
      expect(find.text('Polar H10'), findsOneWidget);
      expect(find.text('Unnamed heart-rate strap'), findsOneWidget);
      expect(find.text('Looking for heart-rate straps…'), findsNothing);
      // Still scanning, and connecting comes later.
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
        find.text("Connecting to a strap isn't available yet."),
        findsOneWidget,
      );
    });

    group('a failed scan', () {
      const messages = {
        BluetoothProblem.off: (
          'Bluetooth is off',
          'Turn on Bluetooth to connect to your strap.',
        ),
        BluetoothProblem.unavailable: (
          "Bluetooth isn't available",
          "This phone can't connect to a heart-rate strap.",
        ),
        BluetoothProblem.permissionDenied: (
          'Bluetooth permission needed',
          'Allow PulseLink to use Bluetooth in Settings, then try again.',
        ),
      };

      test('every problem has a message', () {
        expect(messages.keys, unorderedEquals(BluetoothProblem.values));
      });

      for (final MapEntry(key: problem, value: (title, detail))
          in messages.entries) {
        testWidgets('${problem.name}: says why and what to do', (tester) async {
          await pumpScreen(tester);
          scanner.emit(StrapScanEvent.failed(problem));
          await tester.pump();
          expect(find.text(title), findsOneWidget);
          expect(find.text(detail), findsOneWidget);
          // Scanning resumes by itself once the problem is fixed.
          expect(find.text('Try again'), findsNothing);
        });
      }

      testWidgets('scanning resumes when the problem goes away', (
        tester,
      ) async {
        await pumpScreen(tester);
        scanner.emit(const .failed(.off));
        await tester.pump();
        scanner.emit(const .scanning());
        await tester.pump();
        expect(find.text('Bluetooth is off'), findsNothing);
        expect(find.text('Looking for heart-rate straps…'), findsOneWidget);
      });
    });

    testWidgets('closing the screen stops the scan', (tester) async {
      await pumpScreen(tester);
      expect(scanner.isScanning, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(scanner.isScanning, isFalse);
    });

    testWidgets('every state fits a 320 px wide screen without overflow', (
      tester,
    ) async {
      // Smaller than any current iPhone. Flutter fails the test on overflow.
      tester.view
        ..physicalSize = const Size(320, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpScreen(tester);
      for (final event in [
        const StrapScanEvent.scanning(),
        for (var i = 0; i < 20; i++)
          StrapScanEvent.found(
            discoveredStrapOf(
              'strap-$i',
              'A heart-rate strap with a very long name, number $i',
            ),
          ),
        for (final problem in BluetoothProblem.values)
          StrapScanEvent.failed(problem),
      ]) {
        scanner.emit(event);
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$event');
      }
    });
  });
}
