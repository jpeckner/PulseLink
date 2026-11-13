import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_cubit.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_state.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/ui/live/live_heart_rate_screen.dart';
import 'package:pulselink/ui/widgets/disclaimer_banner.dart';

import '../helpers/positive_int.dart';

class _MockLiveHeartRateCubit extends MockCubit<LiveHeartRateState>
    implements LiveHeartRateCubit;

final _timestamp = DateTime(2026, 11, 11, 10, 52, 31);
final String _time = DateFormat.jms().format(_timestamp);

LiveHeartRateState _reading({
  int bpm = 72,
  SkinContact skinContact = SkinContact.detected,
  bool isStale = false,
  bool isSimulated = false,
}) => LiveHeartRateState.reading(
  sample: HeartRateSample.measured(
    bpm: positiveInt(bpm),
    timestamp: _timestamp,
    skinContact: skinContact,
  ),
  isStale: isStale,
  isSimulated: isSimulated,
);

LiveHeartRateState _unavailable(
  HeartRateUnavailableReason reason, {
  bool isStale = false,
}) => LiveHeartRateState.reading(
  sample: HeartRateSample.unavailable(timestamp: _timestamp, reason: reason),
  isStale: isStale,
  isSimulated: false,
);

void main() {
  group('LiveHeartRateScreen', () {
    late _MockLiveHeartRateCubit cubit;

    setUp(() => cubit = _MockLiveHeartRateCubit());

    Future<void> pumpScreen(WidgetTester tester, LiveHeartRateState state) {
      when(() => cubit.state).thenReturn(state);
      // A new key gives a fresh BlocBuilder, which reads the new state. With
      // the same key, re-pumping keeps the first state it read, so tests that
      // pump several states would silently only check the first.
      return tester.pumpWidget(
        MaterialApp(
          home: LiveHeartRateScreen(key: UniqueKey(), cubit: cubit),
        ),
      );
    }

    testWidgets('always shows the disclaimer', (tester) async {
      await pumpScreen(tester, _reading());
      expect(find.text(disclaimerText), findsOneWidget);
    });

    group('waiting', () {
      testWidgets('shows no number and says it is waiting', (tester) async {
        await pumpScreen(
          tester,
          const LiveHeartRateState.waiting(isSimulated: false),
        );
        expect(find.text('--'), findsOneWidget);
        expect(find.text('Waiting for heart-rate data…'), findsOneWidget);
        expect(find.bySemanticsLabel('No heart-rate reading'), findsOneWidget);
      });
    });

    group('fresh reading', () {
      testWidgets('shows bpm, update time and skin contact', (tester) async {
        await pumpScreen(tester, _reading());
        expect(find.text('72'), findsOneWidget);
        expect(find.text('Updated $_time'), findsOneWidget);
        expect(find.text('Skin contact'), findsOneWidget);
        expect(find.textContaining('No data from strap'), findsNothing);
        expect(find.bySemanticsLabel('72 beats per minute'), findsOneWidget);
      });

      testWidgets('shows no skin-contact chip if the strap cannot detect it', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          _reading(skinContact: SkinContact.notSupported),
        );
        expect(find.text('72'), findsOneWidget);
        expect(find.byType(Chip), findsNothing);
      });
    });

    group('stale reading', () {
      testWidgets('says no data is arriving and when the last reading was', (
        tester,
      ) async {
        await pumpScreen(tester, _reading(isStale: true));
        expect(find.text('No data from strap'), findsOneWidget);
        expect(find.text('Last reading $_time'), findsOneWidget);
        expect(find.textContaining('Updated'), findsNothing);
      });

      testWidgets('dims the number and labels it out of date', (tester) async {
        await pumpScreen(tester, _reading(isStale: true));
        final number = tester.widget<Text>(find.text('72'));
        expect(number.style?.color?.a, lessThan(0.5));
        expect(
          find.bySemanticsLabel(
            'Last reading 72 beats per minute, out of date',
          ),
          findsOneWidget,
        );
      });
    });

    group('strap status chip while stale', () {
      // A hidden chip stays in the tree to keep its space, so check
      // Visibility.of and what a screen reader sees, not mere presence.

      testWidgets('skin contact is hidden: it is out of date too', (
        tester,
      ) async {
        await pumpScreen(tester, _reading());
        expect(
          Visibility.of(tester.element(find.text('Skin contact'))),
          isTrue,
        );
        expect(find.bySemanticsLabel('Skin contact'), findsOneWidget);

        await pumpScreen(tester, _reading(isStale: true));
        expect(
          Visibility.of(tester.element(find.text('Skin contact'))),
          isFalse,
        );
        expect(find.bySemanticsLabel('Skin contact'), findsNothing);
      });

      testWidgets('no skin contact is hidden too', (tester) async {
        await pumpScreen(
          tester,
          _unavailable(HeartRateUnavailableReason.noSkinContact, isStale: true),
        );
        expect(
          Visibility.of(tester.element(find.text('No skin contact'))),
          isFalse,
        );
        expect(find.bySemanticsLabel('No skin contact'), findsNothing);
        expect(find.text('No data from strap'), findsOneWidget);
      });

      testWidgets('hiding it does not move the readout', (tester) async {
        await pumpScreen(tester, _reading());
        final fresh = tester.getCenter(find.text('72'));
        await pumpScreen(tester, _reading(isStale: true));
        final stale = tester.getCenter(find.text('72'));
        // The status line grows from one line to two, which can shift the
        // readout slightly; the chip's reserved space keeps it to that.
        expect((stale.dy - fresh.dy).abs(), lessThan(20));
      });
    });

    group('unavailable reading', () {
      testWidgets('no skinContact: no number, a warning chip, still current', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          _unavailable(HeartRateUnavailableReason.noSkinContact),
        );
        expect(find.text('--'), findsOneWidget);
        expect(find.text('No skin contact'), findsOneWidget);
        expect(find.text('Skin contact'), findsNothing);
        // Packets are still arriving, so this is not "no data from strap".
        expect(find.text('Updated $_time'), findsOneWidget);
        expect(find.bySemanticsLabel('No heart-rate reading'), findsOneWidget);
      });

      testWidgets('zero bpm: no number, and says the sensor has no reading', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          _unavailable(HeartRateUnavailableReason.zeroBpm),
        );
        expect(find.text('--'), findsOneWidget);
        expect(find.text('0'), findsNothing);
        expect(find.text('Strap connected, no heart rate yet'), findsOneWidget);
        expect(find.text('Skin contact'), findsNothing);
      });

      testWidgets('stale: says no data is arriving from the strap', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          _unavailable(HeartRateUnavailableReason.noSkinContact, isStale: true),
        );
        expect(find.text('--'), findsOneWidget);
        expect(find.text('No data from strap'), findsOneWidget);
        expect(find.text('Last reading $_time'), findsOneWidget);
      });
    });

    group('demo badge', () {
      testWidgets('shows for simulated data', (tester) async {
        await pumpScreen(tester, _reading(isSimulated: true));
        expect(find.text('Demo'), findsOneWidget);
      });

      testWidgets('shows while waiting for simulated data', (tester) async {
        await pumpScreen(
          tester,
          const LiveHeartRateState.waiting(isSimulated: true),
        );
        expect(find.text('Demo'), findsOneWidget);
      });

      testWidgets('is hidden for real data', (tester) async {
        await pumpScreen(tester, _reading());
        expect(find.text('Demo'), findsNothing);
      });
    });

    testWidgets('rebuilds as the state changes', (tester) async {
      final states = StreamController<LiveHeartRateState>();
      addTearDown(states.close);
      whenListen(
        cubit,
        states.stream,
        initialState: const LiveHeartRateState.waiting(isSimulated: false),
      );
      await tester.pumpWidget(
        MaterialApp(home: LiveHeartRateScreen(cubit: cubit)),
      );
      expect(find.text('--'), findsOneWidget);

      // pumpAndSettle: the mocked stream takes a few async hops to arrive.
      states.add(_reading(bpm: 80));
      await tester.pumpAndSettle();
      expect(find.text('80'), findsOneWidget);
      expect(find.text('Updated $_time'), findsOneWidget);

      states.add(_reading(bpm: 80, isStale: true));
      await tester.pumpAndSettle();
      expect(find.text('No data from strap'), findsOneWidget);
      expect(find.text('Last reading $_time'), findsOneWidget);
    });

    testWidgets('every state fits a 320 px wide screen without overflow', (
      tester,
    ) async {
      // Smaller than any current iPhone. Flutter fails the test on overflow.
      tester.view
        ..physicalSize = const Size(320, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      for (final state in [
        const LiveHeartRateState.waiting(isSimulated: true),
        _reading(isSimulated: true),
        _reading(isStale: true, isSimulated: true),
        _reading(skinContact: SkinContact.notSupported),
        _unavailable(HeartRateUnavailableReason.noSkinContact),
        _unavailable(HeartRateUnavailableReason.zeroBpm),
        _unavailable(HeartRateUnavailableReason.noSkinContact, isStale: true),
      ]) {
        await pumpScreen(tester, state);
        expect(tester.takeException(), isNull, reason: '$state');
      }
    });
  });
}
