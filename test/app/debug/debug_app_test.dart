import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pulselink/app/composition.dart';
import 'package:pulselink/app/debug/debug_app.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/watch_heart_rate_snapshot.dart';

import '../../helpers/beats_per_minute.dart';
import '../../helpers/discovered_strap.dart';
import '../../helpers/english.dart';
import '../../helpers/fake_watch_bridge.dart';
import '../../helpers/stub_app_settings.dart';
import '../../helpers/stub_strap_data_source.dart';
import '../../helpers/stub_strap_scanner.dart';

void main() {
  group('debugApp', () {
    late StubStrapScanner scanner;
    late FakeWatchBridge watch;
    late StubStrapDataSource strap;

    setUp(() {
      scanner = StubStrapScanner();
      watch = FakeWatchBridge();
      strap = StubStrapDataSource();
    });

    Future<void> pumpDebugApp(WidgetTester tester) async {
      await tester.pumpWidget(
        debugApp(
          AppPlatform(
            strapScanner: scanner,
            appSettings: StubAppSettings(),
            watchBridge: watch,
            createStrapSource: (_) => strap,
          ),
        ),
      );
      await tester.pump();
    }

    /// Picks a strap in the picker. Fixed pumps rather than pumpAndSettle:
    /// the picker's progress indicators animate for as long as it scans.
    Future<void> pickStrap(WidgetTester tester) async {
      await tester.tap(find.byTooltip(english.findStrapTooltip));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      scanner.emit(.found(discoveredStrapOf('polar', 'Polar H10')));
      await tester.pump();
      await tester.tap(find.text('Polar H10'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    /// Lets switching away from the demo source finish. It cancels
    /// subscriptions to the demo source's broadcast streams, and Dart
    /// completes those cancels on the real event loop, which testWidgets'
    /// fake time doesn't run; in the app they finish at once.
    Future<void> settleSwitch(WidgetTester tester) async {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }

    /// Shows the debug override buttons, by long-pressing the title.
    Future<void> showOverride(WidgetTester tester) async {
      await tester.longPress(find.text(english.appTitle));
      await tester.pump();
    }

    testWidgets('starts on real data, with no strap and no demo data', (
      tester,
    ) async {
      await pumpDebugApp(tester);

      expect(find.text(english.noStrapTitle), findsOneWidget);
      expect(find.text(english.demoBadge), findsNothing);
      expect(find.text('Use demo data'), findsNothing);
      expect(watch.contexts.last.status, const WatchHeartRateStatus.noStrap());
      expect(watch.contexts.last.isSimulated, isFalse);
    });

    testWidgets('long-pressing the title shows the three override buttons, '
        'the data toggle first', (tester) async {
      await pumpDebugApp(tester);
      await showOverride(tester);

      final buttons = find.byType(OutlinedButton);
      expect(buttons, findsNWidgets(3));
      expect(
        find.descendant(
          of: buttons.first,
          matching: find.text('Data: Real strap'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Skin-contact detection'), findsOneWidget);
      expect(find.textContaining('Override:'), findsOneWidget);
    });

    testWidgets('the data toggle switches to demo data, and back to no '
        'strap', (tester) async {
      await pumpDebugApp(tester);
      await showOverride(tester);

      await tester.tap(find.text('Data: Real strap'));
      await tester.pump();
      // The demo source sends a reading a second.
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(english.demoBadge), findsOneWidget);
      expect(find.text(english.noStrapTitle), findsNothing);
      expect(find.text(english.beatsPerMinuteUnit), findsOneWidget);
      expect(find.text('Data: Demo'), findsOneWidget);
      expect(watch.contexts.last.isSimulated, isTrue);

      // Back to real data: no strap, as at launch. Disposing the demo
      // source stops its timer.
      await tester.tap(find.text('Data: Demo'));
      await settleSwitch(tester);
      expect(find.text(english.noStrapTitle), findsOneWidget);
      expect(find.text(english.demoBadge), findsNothing);
      expect(find.text('Data: Real strap'), findsOneWidget);
      expect(watch.contexts.last.status, const WatchHeartRateStatus.noStrap());
      expect(watch.contexts.last.isSimulated, isFalse);
    });

    testWidgets('picking a strap replaces demo data', (tester) async {
      await pumpDebugApp(tester);
      await showOverride(tester);
      await tester.tap(find.text('Data: Real strap'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(english.demoBadge), findsOneWidget);

      // Picking a strap disposes the demo source, which stops its timer.
      await pickStrap(tester);
      await settleSwitch(tester);
      expect(strap.startCount, 1);
      expect(find.text(english.demoBadge), findsNothing);
      expect(find.text(english.waitingForData), findsOneWidget);

      strap.emit(
        HeartRateSample.measured(
          beatsPerMinute: beatsPerMinuteOf(72),
          timestamp: clock.now(),
          skinContact: SkinContact.detected,
        ),
      );
      await settleSwitch(tester);
      expect(find.text('72'), findsOneWidget);
      expect(find.text('Data: Real strap'), findsOneWidget);
      expect(watch.contexts.last.isSimulated, isFalse);

      // Lets the reading go stale, so no timer outlives the test.
      await tester.pump(const Duration(seconds: 11));
    });
  });
}
