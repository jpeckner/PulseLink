// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pulselink/app/composition.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/strap_ble_identifier.dart';
import 'package:pulselink/domain/watch_heart_rate_snapshot.dart';

import '../helpers/beats_per_minute.dart';
import '../helpers/discovered_strap.dart';
import '../helpers/english.dart';
import '../helpers/fake_watch_bridge.dart';
import '../helpers/recording_tracker_service.dart';
import '../helpers/stub_app_settings.dart';
import '../helpers/stub_strap_data_source.dart';
import '../helpers/stub_strap_scanner.dart';

void main() {
  group('releaseApp', () {
    late StubStrapScanner scanner;
    late FakeWatchBridge watch;
    late StubStrapDataSource strap;
    late List<StrapBleIdentifier> created;

    setUp(() {
      scanner = StubStrapScanner();
      watch = FakeWatchBridge();
      strap = StubStrapDataSource();
      created = [];
    });

    Future<void> pumpReleaseApp(WidgetTester tester) async {
      await tester.pumpWidget(
        releaseApp(
          AppPlatform(
            strapScanner: scanner,
            appSettings: StubAppSettings(),
            watchBridge: watch,
            tracker: RecordingTrackerService(),
            createStrapSource: (strapId) {
              created.add(strapId);
              return strap;
            },
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('starts with no strap, and nothing simulated or for '
        'debugging', (tester) async {
      await pumpReleaseApp(tester);

      expect(find.text(english.noStrapTitle), findsOneWidget);
      expect(find.text(english.demoBadge), findsNothing);
      expect(find.text('Use demo data'), findsNothing);
      // The debug override's controls, and its title long-press.
      await tester.longPress(find.text(english.appTitle));
      await tester.pump();
      expect(find.textContaining('Override'), findsNothing);
    });

    testWidgets('tells the watch there is no strap, and nothing '
        'simulated', (tester) async {
      await pumpReleaseApp(tester);

      final latest = watch.contexts.last;
      expect(latest.status, const WatchHeartRateStatus.noStrap());
      expect(latest.isSimulated, isFalse);
      expect(latest.latestReading, isNull);
    });

    testWidgets('shows the heart rate from a strap once one is picked', (
      tester,
    ) async {
      await pumpReleaseApp(tester);

      // Fixed pumps rather than pumpAndSettle: the picker's progress
      // indicators animate for as long as it scans.
      await tester.tap(
        find.widgetWithText(FilledButton, english.findStrapButton),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      scanner.emit(.found(discoveredStrapOf('polar', 'Polar H10')));
      await tester.pump();
      await tester.tap(find.text('Polar H10'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(created, [strapIdOf('polar')]);
      expect(strap.startCount, 1);
      expect(find.text(english.waitingForData), findsOneWidget);

      strap.emit(
        HeartRateSample.measured(
          beatsPerMinute: beatsPerMinuteOf(72),
          timestamp: clock.now(),
          skinContact: SkinContact.detected,
        ),
      );
      await tester.pump();
      expect(find.text('72'), findsOneWidget);
      expect(find.text(english.demoBadge), findsNothing);
      expect(
        watch.contexts.last.status,
        const WatchHeartRateStatus.receiving(),
      );

      // Lets the reading go stale, so no timer outlives the test.
      await tester.pump(const Duration(seconds: 11));
    });
  });
}
