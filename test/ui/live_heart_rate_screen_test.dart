import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_cubit.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_state.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/ui/live/live_heart_rate_screen.dart';
import 'package:pulselink/ui/widgets/disclaimer_banner.dart';

class _MockLiveHeartRateCubit extends MockCubit<LiveHeartRateState>
    implements LiveHeartRateCubit;

final _timestamp = DateTime(2026, 11, 11, 10, 52, 31);
final String _time = DateFormat.jms().format(_timestamp);

LiveHeartRateState _reading({
  int bpm = 72,
  SensorContact contact = SensorContact.detected,
  bool isStale = false,
  bool isSimulated = false,
}) => LiveHeartRateState.reading(
  sample: HeartRateSample.measured(
    bpm: bpm,
    timestamp: _timestamp,
    contact: contact,
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
      return tester.pumpWidget(
        BlocProvider<LiveHeartRateCubit>.value(
          value: cubit,
          child: const MaterialApp(home: LiveHeartRateScreen()),
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
      testWidgets('shows bpm, update time and contact', (tester) async {
        await pumpScreen(tester, _reading());
        expect(find.text('72'), findsOneWidget);
        expect(find.text('Updated $_time'), findsOneWidget);
        expect(find.text('Sensor contact'), findsOneWidget);
        expect(find.textContaining('Signal lost'), findsNothing);
        expect(find.bySemanticsLabel('72 beats per minute'), findsOneWidget);
      });

      testWidgets('shows no contact chip if contact is unsupported', (
        tester,
      ) async {
        await pumpScreen(tester, _reading(contact: SensorContact.notSupported));
        expect(find.text('72'), findsOneWidget);
        expect(find.byType(Chip), findsNothing);
      });
    });

    group('stale reading', () {
      testWidgets('says the signal is lost and when the last reading was', (
        tester,
      ) async {
        await pumpScreen(tester, _reading(isStale: true));
        expect(find.text('Signal lost · last reading $_time'), findsOneWidget);
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

    group('unavailable reading', () {
      testWidgets('no contact: no number, a warning chip, still current', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          _unavailable(HeartRateUnavailableReason.noContact),
        );
        expect(find.text('--'), findsOneWidget);
        expect(find.text('No sensor contact'), findsOneWidget);
        expect(find.text('Sensor contact'), findsNothing);
        // Packets are still arriving, so this is not a lost signal.
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
        expect(find.text('No reading from sensor'), findsOneWidget);
        expect(find.text('Sensor contact'), findsNothing);
      });

      testWidgets('stale: shows signal lost', (tester) async {
        await pumpScreen(
          tester,
          _unavailable(HeartRateUnavailableReason.noContact, isStale: true),
        );
        expect(find.text('--'), findsOneWidget);
        expect(find.text('Signal lost · last reading $_time'), findsOneWidget);
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
        BlocProvider<LiveHeartRateCubit>.value(
          value: cubit,
          child: const MaterialApp(home: LiveHeartRateScreen()),
        ),
      );
      expect(find.text('--'), findsOneWidget);

      // pumpAndSettle: the mocked stream takes a few async hops to arrive.
      states.add(_reading(bpm: 80));
      await tester.pumpAndSettle();
      expect(find.text('80'), findsOneWidget);
      expect(find.text('Updated $_time'), findsOneWidget);

      states.add(_reading(bpm: 80, isStale: true));
      await tester.pumpAndSettle();
      expect(find.text('Signal lost · last reading $_time'), findsOneWidget);
    });
  });
}
