import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
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

    testWidgets('starts with no strap, offering demo data', (tester) async {
      await pumpDebugApp(tester);

      expect(find.text(english.noStrapTitle), findsOneWidget);
      expect(find.text('Use demo data'), findsOneWidget);
      expect(find.text(english.demoBadge), findsNothing);
      expect(watch.contexts.last.status, const WatchHeartRateStatus.noStrap());
    });

    testWidgets('demo data shows simulated readings, until a strap is '
        'picked in its place', (tester) async {
      await pumpDebugApp(tester);

      await tester.tap(find.text('Use demo data'));
      await tester.pump();
      // The demo source sends a reading a second.
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(english.demoBadge), findsOneWidget);
      expect(find.text(english.noStrapTitle), findsNothing);
      expect(find.text(english.beatsPerMinuteUnit), findsOneWidget);
      expect(watch.contexts.last.isSimulated, isTrue);

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
      expect(watch.contexts.last.isSimulated, isFalse);

      // Lets the reading go stale, so no timer outlives the test.
      await tester.pump(const Duration(seconds: 11));
    });

    testWidgets('long-pressing the title shows the debug override', (
      tester,
    ) async {
      await pumpDebugApp(tester);

      await tester.longPress(find.text(english.appTitle));
      await tester.pump();
      expect(find.textContaining('Override'), findsOneWidget);
    });
  });
}
