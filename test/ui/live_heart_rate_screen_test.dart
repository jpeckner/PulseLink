import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_cubit.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_state.dart';
import 'package:pulselink/blocs/strap_battery/strap_battery_cubit.dart';
import 'package:pulselink/domain/battery_level.dart';
import 'package:pulselink/domain/bluetooth_problem.dart';
import 'package:pulselink/domain/discovered_strap.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/strap_connection_failure.dart';
import 'package:pulselink/ui/live/live_heart_rate_screen.dart';

import '../helpers/beats_per_minute.dart';
import '../helpers/discovered_strap.dart';
import '../helpers/english.dart';
import '../helpers/strap_connection_failures.dart';
import '../helpers/stub_app_settings.dart';

class _MockLiveHeartRateCubit extends MockCubit<LiveHeartRateState>
    implements LiveHeartRateCubit;

class _MockStrapBatteryCubit extends MockCubit<BatteryLevel?>
    implements StrapBatteryCubit;

final _timestamp = DateTime(2026, 11, 11, 10, 52, 31);
final String _time = DateFormat.jms().format(_timestamp);

LiveHeartRateState _reading({
  int beatsPerMinute = 72,
  SkinContact skinContact = SkinContact.detected,
  bool isStale = false,
  bool isSimulated = false,
}) => LiveHeartRateState.reading(
  sample: HeartRateSample.measured(
    beatsPerMinute: beatsPerMinuteOf(beatsPerMinute),
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

/// For tests that never open the strap picker.
Widget _noPicker(BuildContext context) => const SizedBox.shrink();

/// For tests that never pick a strap.
void _noSelection(DiscoveredStrap strap) {}

void main() {
  group('LiveHeartRateScreen', () {
    late _MockLiveHeartRateCubit cubit;
    late _MockStrapBatteryCubit battery;
    late StubAppSettings settings;

    setUp(() {
      cubit = _MockLiveHeartRateCubit();
      battery = _MockStrapBatteryCubit();
      settings = StubAppSettings();
      when(() => battery.state).thenReturn(null);
    });

    Future<void> pumpScreen(WidgetTester tester, LiveHeartRateState state) {
      when(() => cubit.state).thenReturn(state);
      // A new key gives a fresh BlocBuilder, which reads the new state. With
      // the same key, re-pumping keeps the first state it read, so tests that
      // pump several states would silently only check the first.
      return tester.pumpWidget(
        MaterialApp(
          home: LiveHeartRateScreen(
            key: UniqueKey(),
            cubit: cubit,
            batteryCubit: battery,
            appSettings: settings,
            buildStrapPicker: _noPicker,
            onStrapSelected: _noSelection,
          ),
        ),
      );
    }

    testWidgets('always shows the disclaimer', (tester) async {
      await pumpScreen(tester, _reading());
      expect(find.text(english.disclaimer), findsOneWidget);
    });

    group('no strap', () {
      Future<void> pumpNoStrap(WidgetTester tester) {
        when(() => cubit.state).thenReturn(const LiveHeartRateState.noStrap());
        return tester.pumpWidget(
          MaterialApp(
            home: LiveHeartRateScreen(
              cubit: cubit,
              batteryCubit: battery,
              appSettings: settings,
              buildStrapPicker: (_) => const Text('strap picker'),
              onStrapSelected: _noSelection,
            ),
          ),
        );
      }

      testWidgets('asks for a strap, with no reading and no Demo badge', (
        tester,
      ) async {
        await pumpNoStrap(tester);
        expect(find.text(english.noStrapTitle), findsOneWidget);
        expect(find.text(english.noStrapDetail), findsOneWidget);
        expect(find.text('--'), findsNothing);
        expect(find.text(english.demoBadge), findsNothing);
      });

      testWidgets('its Find strap button opens the strap picker', (
        tester,
      ) async {
        await pumpNoStrap(tester);
        await tester.tap(
          find.widgetWithText(FilledButton, english.findStrapButton),
        );
        await tester.pumpAndSettle();
        expect(find.text('strap picker'), findsOneWidget);
      });
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
        // An invisible chip keeps the space; see the next test.
        expect(
          Visibility.of(tester.element(find.text('Skin contact'))),
          isFalse,
        );
        expect(find.bySemanticsLabel('Skin contact'), findsNothing);
      });

      testWidgets('the readout sits in the same place with or without it', (
        tester,
      ) async {
        await pumpScreen(tester, _reading());
        final detected = tester.getCenter(find.text('72'));
        await pumpScreen(
          tester,
          _reading(skinContact: SkinContact.notSupported),
        );
        expect(tester.getCenter(find.text('72')), detected);
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
          _unavailable(HeartRateUnavailableReason.zeroBeatsPerMinute),
        );
        expect(find.text('--'), findsOneWidget);
        expect(find.text('0'), findsNothing);
        expect(find.text('Strap connected, no heart rate yet'), findsOneWidget);
        expect(find.text('Skin contact'), findsNothing);
      });

      testWidgets('implausible bpm: no number, and an out-of-range warning', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          _unavailable(HeartRateUnavailableReason.implausibleBeatsPerMinute),
        );
        expect(find.text('--'), findsOneWidget);
        expect(find.text('Strap reading out of range'), findsOneWidget);
        expect(find.text('Skin contact'), findsNothing);
        // Packets are still arriving, so this is not "no data from strap".
        expect(find.text('Updated $_time'), findsOneWidget);
        expect(find.bySemanticsLabel('No heart-rate reading'), findsOneWidget);
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

    group('connection failed', () {
      final messages = {
        const StrapConnectionFailure.bluetooth(BluetoothProblem.off): (
          'Bluetooth is off',
          'Turn on Bluetooth to connect to your strap.',
          false,
        ),
        const StrapConnectionFailure.bluetooth(BluetoothProblem.unavailable): (
          "Bluetooth isn't available",
          "This phone can't connect to a heart-rate strap.",
          false,
        ),
        const StrapConnectionFailure.bluetooth(
          BluetoothProblem.permissionDenied,
        ): (
          'Bluetooth permission needed',
          'Allow PulseLink to use Bluetooth in Settings, then try again.',
          true,
        ),
        const StrapConnectionFailure.strapUnreachable(): (
          "Can't reach the strap",
          "Make sure it's on, being worn and nearby, and not connected to "
              'another app.',
          false,
        ),
        const StrapConnectionFailure.notAHeartRateStrap(): (
          'Not a heart-rate strap',
          "This device doesn't send heart-rate data.",
          false,
        ),
        const StrapConnectionFailure.connectionLost(): (
          'Strap disconnected',
          "Make sure it's on, being worn and nearby, then try again.",
          false,
        ),
      };

      test('every failure has a message', () {
        expect(messages.keys, unorderedEquals(allStrapConnectionFailures));
      });

      for (final MapEntry(key: failure, value: (title, detail, hasSettings))
          in messages.entries) {
        testWidgets('$failure: says why, what to do, and no number', (
          tester,
        ) async {
          await pumpScreen(
            tester,
            LiveHeartRateState.connectionFailed(
              failure: failure,
              isSimulated: false,
            ),
          );
          expect(find.text(title), findsOneWidget);
          expect(find.text(detail), findsOneWidget);
          expect(find.text('Try again'), findsOneWidget);
          expect(
            find.text('Open Settings'),
            hasSettings ? findsOneWidget : findsNothing,
          );
          expect(find.text('--'), findsNothing);
          expect(find.text('bpm'), findsNothing);
        });
      }

      testWidgets('Open Settings opens the settings', (tester) async {
        await pumpScreen(
          tester,
          const LiveHeartRateState.connectionFailed(
            failure: .bluetooth(.permissionDenied),
            isSimulated: false,
          ),
        );
        await tester.tap(find.text('Open Settings'));
        await tester.pump();
        expect(settings.openCount, 1);
      });

      testWidgets('Try again starts the cubit again', (tester) async {
        when(() => cubit.start()).thenAnswer((_) async {});
        await pumpScreen(
          tester,
          const LiveHeartRateState.connectionFailed(
            failure: StrapConnectionFailure.bluetooth(BluetoothProblem.off),
            isSimulated: false,
          ),
        );
        await tester.tap(find.text('Try again'));
        verify(() => cubit.start()).called(1);
      });
    });

    testWidgets('Find strap opens the strap picker', (tester) async {
      when(() => cubit.state)
          .thenReturn(const LiveHeartRateState.waiting(isSimulated: false));
      await tester.pumpWidget(
        MaterialApp(
          home: LiveHeartRateScreen(
            cubit: cubit,
            batteryCubit: battery,
            appSettings: settings,
            buildStrapPicker: (_) => const Text('strap picker'),
            onStrapSelected: _noSelection,
          ),
        ),
      );
      await tester.tap(find.byTooltip('Find strap'));
      await tester.pumpAndSettle();
      expect(find.text('strap picker'), findsOneWidget);
    });

    group('battery level', () {
      Future<void> pumpWithBattery(WidgetTester tester, int? percent) {
        when(() => battery.state)
            .thenReturn(percent == null ? null : BatteryLevel.tryFrom(percent));
        return pumpScreen(tester, _reading());
      }

      testWidgets('shows the percentage once known', (tester) async {
        await pumpWithBattery(tester, 85);
        expect(find.text('85%'), findsOneWidget);
        expect(find.byIcon(Icons.battery_std), findsOneWidget);
        expect(
          find.bySemanticsLabel('Strap battery 85 percent'),
          findsOneWidget,
        );
      });

      testWidgets('warns once it is low', (tester) async {
        await pumpWithBattery(tester, 15);
        expect(find.text('15%'), findsOneWidget);
        expect(find.byIcon(Icons.battery_alert), findsOneWidget);
        expect(
          find.bySemanticsLabel('Strap battery 15 percent, low'),
          findsOneWidget,
        );
      });

      testWidgets('shows nothing while it is unknown', (tester) async {
        await pumpWithBattery(tester, null);
        expect(find.textContaining('%'), findsNothing);
        expect(find.byIcon(Icons.battery_std), findsNothing);
      });

      testWidgets('fits a 320 px wide app bar with the Demo badge', (
        tester,
      ) async {
        tester.view
          ..physicalSize = const Size(320, 640)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        when(() => battery.state).thenReturn(BatteryLevel.tryFrom(100));
        await pumpScreen(tester, _reading(isSimulated: true));
        expect(tester.takeException(), isNull);
        expect(find.text('100%'), findsOneWidget);
        expect(find.text('Demo'), findsOneWidget);
      });
    });

    group('picking a strap', () {
      late List<DiscoveredStrap> selected;
      final strap = discoveredStrapOf('strap-1', 'TICKR');

      Future<void> pumpWithPicker(
        WidgetTester tester, {
        required DiscoveredStrap? pickedStrap,
      }) {
        selected = [];
        when(() => cubit.state)
            .thenReturn(const LiveHeartRateState.waiting(isSimulated: true));
        return tester.pumpWidget(
          MaterialApp(
            home: LiveHeartRateScreen(
              cubit: cubit,
              batteryCubit: battery,
              appSettings: settings,
              // A stand-in picker that closes with pickedStrap.
              buildStrapPicker: (context) => TextButton(
                onPressed: () => Navigator.of(context).pop(pickedStrap),
                child: const Text('close picker'),
              ),
              onStrapSelected: selected.add,
            ),
          ),
        );
      }

      testWidgets('passes on the strap picked in the picker', (tester) async {
        await pumpWithPicker(tester, pickedStrap: strap);
        await tester.tap(find.byTooltip('Find strap'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('close picker'));
        await tester.pumpAndSettle();
        expect(selected, [strap]);
      });

      testWidgets('closing the picker without picking passes nothing on', (
        tester,
      ) async {
        await pumpWithPicker(tester, pickedStrap: null);
        await tester.tap(find.byTooltip('Find strap'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('close picker'));
        await tester.pumpAndSettle();
        expect(selected, isEmpty);
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
        MaterialApp(
          home: LiveHeartRateScreen(
            cubit: cubit,
            batteryCubit: battery,
            appSettings: settings,
            buildStrapPicker: _noPicker,
            onStrapSelected: _noSelection,
          ),
        ),
      );
      expect(find.text('--'), findsOneWidget);

      // pumpAndSettle: the mocked stream takes a few async hops to arrive.
      states.add(_reading(beatsPerMinute: 80));
      await tester.pumpAndSettle();
      expect(find.text('80'), findsOneWidget);
      expect(find.text('Updated $_time'), findsOneWidget);

      states.add(_reading(beatsPerMinute: 80, isStale: true));
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
        _unavailable(HeartRateUnavailableReason.zeroBeatsPerMinute),
        _unavailable(HeartRateUnavailableReason.implausibleBeatsPerMinute),
        _unavailable(HeartRateUnavailableReason.noSkinContact, isStale: true),
        for (final failure in allStrapConnectionFailures)
          LiveHeartRateState.connectionFailed(
            failure: failure,
            isSimulated: false,
          ),
      ]) {
        await pumpScreen(tester, state);
        expect(tester.takeException(), isNull, reason: '$state');
      }
    });

    group('debug inputs', () {
      testWidgets('shows debug controls just above the disclaimer', (
        tester,
      ) async {
        when(() => cubit.state).thenReturn(_reading());
        await tester.pumpWidget(
          MaterialApp(
            home: LiveHeartRateScreen(
              cubit: cubit,
              batteryCubit: battery,
              appSettings: settings,
              buildStrapPicker: _noPicker,
              onStrapSelected: _noSelection,
              debugControls: const Text('debug controls'),
            ),
          ),
        );
        final controls = tester.getTopLeft(find.text('debug controls'));
        final disclaimer = tester.getTopLeft(find.text(english.disclaimer));
        expect(controls.dy, lessThan(disclaimer.dy));
      });

      testWidgets('debug controls never move the readout', (tester) async {
        when(() => cubit.state).thenReturn(_reading());
        Future<Offset> readoutCenter(Widget? debugControls) async {
          await tester.pumpWidget(
            MaterialApp(
              home: LiveHeartRateScreen(
                cubit: cubit,
                batteryCubit: battery,
                appSettings: settings,
                buildStrapPicker: _noPicker,
                onStrapSelected: _noSelection,
                debugControls: debugControls,
              ),
            ),
          );
          return tester.getCenter(find.text('72'));
        }

        // Release builds pass no controls; debug builds pass the button,
        // which is empty while hidden and about 60 px tall when shown.
        final release = await readoutCenter(null);
        final hidden = await readoutCenter(const SizedBox.shrink());
        final shown = await readoutCenter(
          const SizedBox(height: 60, child: Text('debug controls')),
        );
        expect(hidden, release);
        expect(shown, release);
      });

      testWidgets('long-pressing the title calls onTitleLongPress', (
        tester,
      ) async {
        var longPresses = 0;
        when(() => cubit.state).thenReturn(_reading());
        await tester.pumpWidget(
          MaterialApp(
            home: LiveHeartRateScreen(
              cubit: cubit,
              batteryCubit: battery,
              appSettings: settings,
              buildStrapPicker: _noPicker,
              onStrapSelected: _noSelection,
              onTitleLongPress: () => longPresses++,
            ),
          ),
        );
        await tester.longPress(find.text('PulseLink'));
        expect(longPresses, 1);
      });

      testWidgets('without debug inputs, nothing extra is shown', (
        tester,
      ) async {
        await pumpScreen(tester, _reading());
        await tester.longPress(find.text('PulseLink'));
        await tester.pump();
        expect(find.byType(OutlinedButton), findsNothing);
      });
    });
  });
}
