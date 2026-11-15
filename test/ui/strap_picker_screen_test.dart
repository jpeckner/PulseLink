import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pulselink/data/strap_scanner.dart';
import 'package:pulselink/domain/bluetooth_problem.dart';
import 'package:pulselink/domain/discovered_strap.dart';
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
      // Still scanning, and connecting comes later. Neither is connected.
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.text('Tap your strap to connect to it.'), findsOneWidget);
    });

    testWidgets('marks a strap that is already connected with a green check, '
        'in place of the progress bar', (tester) async {
      await pumpScreen(tester);
      scanner
        ..emit(.found(discoveredStrapOf('polar', 'Polar H10')))
        ..emit(.found(connectedStrapOf('tickr', 'TICKR')));
      await tester.pump();

      final check = find.byIcon(Icons.check_circle);
      expect(check, findsOneWidget);
      expect(tester.widget<Icon>(check).color, Colors.green);
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'TICKR'),
          matching: check,
        ),
        findsOneWidget,
      );
      // ListTile merges the row into one label, so screen readers say the
      // strap's name, then that it's connected.
      expect(
        find.bySemanticsLabel(RegExp(r'^TICKR\s+Connected$')),
        findsOneWidget,
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('tapping a strap closes the picker with that strap', (
      tester,
    ) async {
      DiscoveredStrap? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                picked = await Navigator.of(context).push(
                  MaterialPageRoute<DiscoveredStrap>(
                    builder: (_) => StrapPickerScreen(scanner: scanner),
                  ),
                );
              },
              child: const Text('open picker'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open picker'));
      // Not pumpAndSettle: the picker's progress indicators never settle.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final strap = discoveredStrapOf('polar', 'Polar H10');
      scanner.emit(StrapScanEvent.found(strap));
      await tester.pump();

      await tester.tap(find.text('Polar H10'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(picked, strap);
      expect(find.text('Find your strap'), findsNothing);
      expect(scanner.isScanning, isFalse);
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
        StrapScanEvent.found(
          connectedStrapOf(
            'connected',
            'A connected heart-rate strap with a very long name',
          ),
        ),
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
