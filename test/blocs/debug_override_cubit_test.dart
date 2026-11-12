import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/blocs/debug_override/debug_override_cubit.dart';
import 'package:pulselink/blocs/debug_override/debug_override_state.dart';
import 'package:pulselink/data/debug_override_heart_rate_source.dart';

import '../helpers/stub_heart_rate_source.dart';

void main() {
  group('DebugOverrideCubit', () {
    late DebugOverrideHeartRateSource source;

    setUp(() => source = DebugOverrideHeartRateSource(StubHeartRateSource()));

    DebugOverrideCubit build() => DebugOverrideCubit(source: source);

    test('starts hidden, with no override', () {
      expect(build().state, const DebugOverrideState.hidden());
      expect(source.mode, ReadingOverride.normal);
    });

    blocTest<DebugOverrideCubit, DebugOverrideState>(
      'toggling shows the button at Normal',
      build: build,
      act: (cubit) => cubit.toggleVisibility(),
      expect: () => [const DebugOverrideState.shown(ReadingOverride.normal)],
      verify: (_) => expect(source.mode, ReadingOverride.normal),
    );

    blocTest<DebugOverrideCubit, DebugOverrideState>(
      'each tap moves to the next override and applies it to the source',
      build: build,
      act: (cubit) {
        cubit.toggleVisibility();
        expect(source.mode, ReadingOverride.normal);
        cubit.cycleMode();
        expect(source.mode, ReadingOverride.stale);
        cubit.cycleMode();
        expect(source.mode, ReadingOverride.noSkinContact);
        cubit.cycleMode();
        expect(source.mode, ReadingOverride.zeroBpm);
        cubit.cycleMode();
        expect(source.mode, ReadingOverride.normal);
      },
      expect: () => const [
        DebugOverrideState.shown(ReadingOverride.normal),
        DebugOverrideState.shown(ReadingOverride.stale),
        DebugOverrideState.shown(ReadingOverride.noSkinContact),
        DebugOverrideState.shown(ReadingOverride.zeroBpm),
        DebugOverrideState.shown(ReadingOverride.normal),
      ],
    );

    blocTest<DebugOverrideCubit, DebugOverrideState>(
      'hiding the button turns the override off',
      build: build,
      act: (cubit) {
        cubit
          ..toggleVisibility()
          ..cycleMode()
          ..cycleMode();
        expect(source.mode, ReadingOverride.noSkinContact);
        cubit.toggleVisibility();
      },
      expect: () => const [
        DebugOverrideState.shown(ReadingOverride.normal),
        DebugOverrideState.shown(ReadingOverride.stale),
        DebugOverrideState.shown(ReadingOverride.noSkinContact),
        DebugOverrideState.hidden(),
      ],
      verify: (_) => expect(source.mode, ReadingOverride.normal),
    );

    blocTest<DebugOverrideCubit, DebugOverrideState>(
      'showing it again starts back at Normal',
      build: build,
      act: (cubit) => cubit
        ..toggleVisibility()
        ..cycleMode()
        ..toggleVisibility()
        ..toggleVisibility(),
      skip: 3,
      expect: () => [const DebugOverrideState.shown(ReadingOverride.normal)],
      verify: (_) => expect(source.mode, ReadingOverride.normal),
    );

    blocTest<DebugOverrideCubit, DebugOverrideState>(
      'tapping does nothing while hidden',
      build: build,
      act: (cubit) => cubit.cycleMode(),
      expect: () => <DebugOverrideState>[],
      verify: (_) => expect(source.mode, ReadingOverride.normal),
    );

    test('does nothing after close', () async {
      final cubit = build();
      await cubit.close();
      cubit
        ..toggleVisibility()
        ..cycleMode();
      expect(cubit.state, const DebugOverrideState.hidden());
      expect(source.mode, ReadingOverride.normal);
    });
  });
}
