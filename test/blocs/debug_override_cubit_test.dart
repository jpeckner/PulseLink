import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/blocs/debug_override/debug_override_cubit.dart';
import 'package:pulselink/blocs/debug_override/debug_override_state.dart';
import 'package:pulselink/data/debug_override_heart_rate_source.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';

import '../helpers/beats_per_minute.dart';
import '../helpers/stub_heart_rate_source.dart';

const ReadingOverride Function(DetectingStrapCondition condition) _detecting =
    ReadingOverride.detectingStrap;
const ReadingOverride Function(NonDetectingStrapCondition condition)
_nonDetecting = ReadingOverride.nonDetectingStrap;

DebugOverrideState _shown(ReadingOverride readingOverride) =>
    DebugOverrideState.shown(readingOverride);

void main() {
  group('DebugOverrideCubit', () {
    late StubHeartRateSource inner;
    late DebugOverrideHeartRateSource source;

    setUp(() {
      inner = StubHeartRateSource();
      source = DebugOverrideHeartRateSource(inner);
      source.samples.listen((_) {});
    });

    DebugOverrideCubit build() => DebugOverrideCubit(source: source);

    void emitMeasured(SkinContact skinContact) => inner.emit(
      HeartRateSample.measured(
        beatsPerMinute: beatsPerMinuteOf(72),
        timestamp: DateTime(2026, 11, 11),
        skinContact: skinContact,
      ),
    );

    test('starts hidden, with no override', () {
      expect(build().state, const DebugOverrideState.hidden());
      expect(source.readingOverride, isNull);
    });

    group('revealing matches the strap, so nothing on screen changes', () {
      blocTest<DebugOverrideCubit, DebugOverrideState>(
        'a strap that detects skin contact',
        build: build,
        setUp: () => emitMeasured(SkinContact.detected),
        act: (cubit) => cubit.toggleVisibility(),
        expect: () => [_shown(_detecting(DetectingStrapCondition.normal))],
      );

      blocTest<DebugOverrideCubit, DebugOverrideState>(
        "a strap that can't detect skin contact",
        build: build,
        setUp: () => emitMeasured(SkinContact.notSupported),
        act: (cubit) => cubit.toggleVisibility(),
        expect: () => [
          _shown(_nonDetecting(NonDetectingStrapCondition.normal)),
        ],
      );

      blocTest<DebugOverrideCubit, DebugOverrideState>(
        'a strap that has not said yet is treated as detecting',
        build: build,
        act: (cubit) => cubit.toggleVisibility(),
        expect: () => [_shown(_detecting(DetectingStrapCondition.normal))],
      );
    });

    blocTest<DebugOverrideCubit, DebugOverrideState>(
      'cycling conditions applies each one to the source',
      build: build,
      act: (cubit) {
        cubit.toggleVisibility();
        for (final condition in [
          DetectingStrapCondition.stale,
          DetectingStrapCondition.noSkinContact,
          DetectingStrapCondition.zeroBeatsPerMinute,
          DetectingStrapCondition.implausibleBeatsPerMinute,
          DetectingStrapCondition.normal,
        ]) {
          cubit.cycleCondition();
          expect(source.readingOverride, _detecting(condition));
        }
      },
      skip: 1,
      expect: () => [
        _shown(_detecting(DetectingStrapCondition.stale)),
        _shown(_detecting(DetectingStrapCondition.noSkinContact)),
        _shown(_detecting(DetectingStrapCondition.zeroBeatsPerMinute)),
        _shown(_detecting(DetectingStrapCondition.implausibleBeatsPerMinute)),
        _shown(_detecting(DetectingStrapCondition.normal)),
      ],
    );

    blocTest<DebugOverrideCubit, DebugOverrideState>(
      'a non-detecting strap never offers no skin contact',
      build: build,
      act: (cubit) => cubit
        ..toggleVisibility()
        ..toggleSkinContactDetection()
        ..cycleCondition()
        ..cycleCondition()
        ..cycleCondition()
        ..cycleCondition(),
      skip: 2,
      expect: () => [
        _shown(_nonDetecting(NonDetectingStrapCondition.stale)),
        _shown(_nonDetecting(NonDetectingStrapCondition.zeroBeatsPerMinute)),
        _shown(
          _nonDetecting(NonDetectingStrapCondition.implausibleBeatsPerMinute),
        ),
        _shown(_nonDetecting(NonDetectingStrapCondition.normal)),
      ],
    );

    blocTest<DebugOverrideCubit, DebugOverrideState>(
      'switching strap keeps a shared condition',
      build: build,
      act: (cubit) => cubit
        ..toggleVisibility()
        ..cycleCondition()
        ..toggleSkinContactDetection()
        ..toggleSkinContactDetection(),
      skip: 2,
      expect: () => [
        _shown(_nonDetecting(NonDetectingStrapCondition.stale)),
        _shown(_detecting(DetectingStrapCondition.stale)),
      ],
      verify: (_) => expect(
        source.readingOverride,
        _detecting(DetectingStrapCondition.stale),
      ),
    );

    blocTest<DebugOverrideCubit, DebugOverrideState>(
      'switching strap from no skin contact goes to normal',
      build: build,
      act: (cubit) => cubit
        ..toggleVisibility()
        ..cycleCondition()
        ..cycleCondition()
        ..toggleSkinContactDetection(),
      skip: 3,
      expect: () => [_shown(_nonDetecting(NonDetectingStrapCondition.normal))],
    );

    blocTest<DebugOverrideCubit, DebugOverrideState>(
      'hiding the buttons turns the override off',
      build: build,
      act: (cubit) => cubit
        ..toggleVisibility()
        ..toggleSkinContactDetection()
        ..cycleCondition()
        ..toggleVisibility(),
      skip: 3,
      expect: () => [const DebugOverrideState.hidden()],
      verify: (_) => expect(source.readingOverride, isNull),
    );

    blocTest<DebugOverrideCubit, DebugOverrideState>(
      'the buttons do nothing while hidden',
      build: build,
      act: (cubit) => cubit
        ..cycleCondition()
        ..toggleSkinContactDetection(),
      expect: () => <DebugOverrideState>[],
      verify: (_) => expect(source.readingOverride, isNull),
    );

    test('does nothing after close', () async {
      final cubit = build();
      await cubit.close();
      cubit
        ..toggleVisibility()
        ..toggleSkinContactDetection()
        ..cycleCondition();
      expect(cubit.state, const DebugOverrideState.hidden());
      expect(source.readingOverride, isNull);
    });
  });
}
