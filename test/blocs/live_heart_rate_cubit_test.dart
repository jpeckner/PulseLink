import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_cubit.dart';
import 'package:pulselink/blocs/live_heart_rate/live_heart_rate_state.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';

import '../helpers/bpm.dart';
import '../helpers/failing_heart_rate_source.dart';
import '../helpers/stub_heart_rate_source.dart';

final _start = DateTime(2026, 11, 11, 10);

HeartRateSample _sampleAt(DateTime timestamp, {int bpm = 72}) =>
    HeartRateSample.measured(
      bpm: bpmOf(bpm),
      timestamp: timestamp,
      skinContact: SkinContact.detected,
    );

/// Runs [body] with fake time and a matching [clock], against a started cubit,
/// collecting every state it emits.
void _withStartedCubit(
  void Function(
    FakeAsync async,
    StubHeartRateSource source,
    LiveHeartRateCubit cubit,
    List<LiveHeartRateState> states,
  )
  body,
) {
  fakeAsync((async) {
    withClock(async.getClock(_start), () {
      final source = StubHeartRateSource();
      final cubit = LiveHeartRateCubit(source: source);
      final states = <LiveHeartRateState>[];
      cubit.stream.listen(states.add);
      unawaited(cubit.start());
      async.flushMicrotasks();

      body(async, source, cubit, states);

      unawaited(cubit.close());
      async.flushMicrotasks();
    });
  });
}

void main() {
  group('LiveHeartRateCubit', () {
    test('starts out waiting, passing on whether the source is simulated', () {
      expect(
        LiveHeartRateCubit(source: StubHeartRateSource(isSimulated: true))
            .state,
        const LiveHeartRateState.waiting(isSimulated: true),
      );
      expect(
        LiveHeartRateCubit(source: StubHeartRateSource()).state,
        const LiveHeartRateState.waiting(isSimulated: false),
      );
    });

    group('start', () {
      late StubHeartRateSource source;

      setUp(() => source = StubHeartRateSource());

      blocTest<LiveHeartRateCubit, LiveHeartRateState>(
        'subscribes to the source and starts it',
        build: () => LiveHeartRateCubit(source: source),
        act: (cubit) async {
          await cubit.start();
          // Checked here: blocTest closes the cubit before `verify` runs.
          expect(source.hasListener, isTrue);
        },
        verify: (_) => expect(source.startCount, 1),
      );

      blocTest<LiveHeartRateCubit, LiveHeartRateState>(
        'can be called twice without subscribing twice',
        build: () => LiveHeartRateCubit(source: source),
        act: (cubit) async {
          await cubit.start();
          await cubit.start();
          source.emit(_sampleAt(clock.now()));
        },
        expect: () => [isA<LiveHeartRateReading>()],
      );
    });

    test('emits a fresh reading for each sample', () {
      _withStartedCubit((async, source, cubit, states) {
        final first = _sampleAt(clock.now());
        source.emit(first);
        async.elapse(const Duration(seconds: 1));
        final second = _sampleAt(clock.now(), bpm: 75);
        source.emit(second);
        async.flushMicrotasks();

        expect(states, [
          LiveHeartRateState.reading(
            sample: first,
            isStale: false,
            isSimulated: false,
          ),
          LiveHeartRateState.reading(
            sample: second,
            isStale: false,
            isSimulated: false,
          ),
        ]);
      });
    });

    test('marks the reading stale 10 s after its timestamp', () {
      _withStartedCubit((async, source, cubit, states) {
        final sample = _sampleAt(clock.now());
        source.emit(sample);

        async.elapse(
          const Duration(seconds: 10) - const Duration(milliseconds: 1),
        );
        expect(cubit.state, isA<LiveHeartRateReading>());
        expect((cubit.state as LiveHeartRateReading).isStale, isFalse);

        async.elapse(const Duration(milliseconds: 1));
        expect(
          cubit.state,
          LiveHeartRateState.reading(
            sample: sample,
            isStale: true,
            isSimulated: false,
          ),
        );
        expect(states, hasLength(2));
      });
    });

    test('each new sample restarts the stale countdown', () {
      _withStartedCubit((async, source, cubit, states) {
        source.emit(_sampleAt(clock.now()));
        async.elapse(const Duration(seconds: 8));
        source.emit(_sampleAt(clock.now()));
        async.elapse(const Duration(seconds: 8));
        expect((cubit.state as LiveHeartRateReading).isStale, isFalse);

        async.elapse(const Duration(seconds: 2));
        expect((cubit.state as LiveHeartRateReading).isStale, isTrue);
      });
    });

    test('a sample that arrives already old is stale at once', () {
      _withStartedCubit((async, source, cubit, states) {
        source.emit(
          _sampleAt(clock.now().subtract(const Duration(seconds: 11))),
        );
        expect((cubit.state as LiveHeartRateReading).isStale, isTrue);
      });
    });

    test('measures age from the sample timestamp, not arrival time', () {
      _withStartedCubit((async, source, cubit, states) {
        source.emit(
          _sampleAt(clock.now().subtract(const Duration(seconds: 7))),
        );
        async.elapse(const Duration(seconds: 3));
        expect((cubit.state as LiveHeartRateReading).isStale, isTrue);
      });
    });

    test('a new sample after going stale is fresh again', () {
      _withStartedCubit((async, source, cubit, states) {
        source.emit(_sampleAt(clock.now()));
        async.elapse(const Duration(seconds: 15));
        expect((cubit.state as LiveHeartRateReading).isStale, isTrue);

        source.emit(_sampleAt(clock.now(), bpm: 80));
        final reading = cubit.state as LiveHeartRateReading;
        expect(reading.isStale, isFalse);
        expect(
          reading.sample,
          isA<MeasuredHeartRateSample>().having((s) => s.bpm.value, 'bpm', 80),
        );
      });
    });

    test('a slightly old sample goes stale at the right moment', () {
      _withStartedCubit((async, source, cubit, states) {
        source.emit(
          _sampleAt(clock.now().subtract(const Duration(seconds: 4))),
        );
        async.elapse(const Duration(seconds: 5));
        expect((cubit.state as LiveHeartRateReading).isStale, isFalse);
        async.elapse(const Duration(seconds: 1));
        expect((cubit.state as LiveHeartRateReading).isStale, isTrue);
      });
    });

    test('a sample stamped in the future goes stale 10 s after it arrives', () {
      _withStartedCubit((async, source, cubit, states) {
        // As if the clock was set back an hour after the sample was stamped.
        source.emit(_sampleAt(clock.now().add(const Duration(hours: 1))));
        async.elapse(
          const Duration(seconds: 10) - const Duration(milliseconds: 1),
        );
        expect((cubit.state as LiveHeartRateReading).isStale, isFalse);
        async.elapse(const Duration(milliseconds: 1));
        expect((cubit.state as LiveHeartRateReading).isStale, isTrue);
      });
    });

    group('unavailable samples', () {
      HeartRateSample unavailableAt(DateTime timestamp) =>
          HeartRateSample.unavailable(
            timestamp: timestamp,
            reason: HeartRateUnavailableReason.noSkinContact,
          );

      test('count as fresh data: the strap is connected and sending', () {
        _withStartedCubit((async, source, cubit, states) {
          final sample = unavailableAt(clock.now());
          source.emit(sample);
          expect(
            cubit.state,
            LiveHeartRateState.reading(
              sample: sample,
              isStale: false,
              isSimulated: false,
            ),
          );
        });
      });

      test('restart the stale countdown after a measured sample', () {
        _withStartedCubit((async, source, cubit, states) {
          source.emit(_sampleAt(clock.now()));
          async.elapse(const Duration(seconds: 8));
          source.emit(unavailableAt(clock.now()));
          async.elapse(const Duration(seconds: 8));
          expect((cubit.state as LiveHeartRateReading).isStale, isFalse);
        });
      });

      test('go stale like any other sample', () {
        _withStartedCubit((async, source, cubit, states) {
          source.emit(unavailableAt(clock.now()));
          async.elapse(const Duration(seconds: 10));
          expect((cubit.state as LiveHeartRateReading).isStale, isTrue);
        });
      });
    });

    test('honors a custom stale threshold', () {
      fakeAsync((async) {
        withClock(async.getClock(_start), () {
          final source = StubHeartRateSource();
          final cubit = LiveHeartRateCubit(
            source: source,
            staleAfter: const Duration(seconds: 3),
          );
          unawaited(cubit.start());
          async.flushMicrotasks();
          source.emit(_sampleAt(clock.now()));
          async.elapse(const Duration(seconds: 3));
          expect((cubit.state as LiveHeartRateReading).isStale, isTrue);
          unawaited(cubit.close());
          async.flushMicrotasks();
        });
      });
    });

    // Real async rather than fake_async: Stream subscription cancel()
    // completes on the real microtask queue, which fake_async never drains.
    test(
      'close stops the source, unsubscribes and cancels the timer',
      () async {
        final source = StubHeartRateSource();
        final cubit = LiveHeartRateCubit(
          source: source,
          staleAfter: const Duration(milliseconds: 20),
        );
        await cubit.start();
        source.emit(_sampleAt(clock.now()));

        await cubit.close();
        expect(source.stopCount, 1);
        expect(source.hasListener, isFalse);
        expect(cubit.isClosed, isTrue);

        // If the stale timer survived close, it would emit into a closed cubit
        // and throw, failing this test.
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
    );

    // Regression: a sample arriving while close() waited on stop() used to
    // start a new stale timer that later emitted into the closed cubit.
    test('a sample arriving while the source stops cannot crash it', () async {
      final source = _SlowStopSource();
      final cubit = LiveHeartRateCubit(
        source: source,
        staleAfter: const Duration(milliseconds: 20),
      );
      await cubit.start();

      await cubit.close();
      expect(source.emittedDuringStop, isTrue);

      // Long enough for any stale timer started during close to fire.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state, const LiveHeartRateState.waiting(isSimulated: false));
    });

    group('close still finishes when', () {
      for (final failure in HeartRateSourceFailure.values) {
        test(failure.description, () async {
          final source = FailingHeartRateSource(failure);
          final cubit = LiveHeartRateCubit(
            source: source,
            staleAfter: const Duration(milliseconds: 20),
          );
          await cubit.start();
          source.emit(_sampleAt(clock.now()));
          expect(cubit.state, isA<LiveHeartRateReading>());

          await expectLater(
            cubit.close(),
            throwsA(same(heartRateSourceFailure)),
          );
          expect(cubit.isClosed, isTrue);
          expect(source.hasListener, isFalse);

          // If the stale timer survived close, it would emit into a closed
          // cubit and throw, failing this test.
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
      }
    });

    test('start after close does nothing', () async {
      final source = StubHeartRateSource();
      final cubit = LiveHeartRateCubit(source: source);
      await cubit.close();

      await cubit.start();
      expect(source.startCount, 0);
      expect(source.hasListener, isFalse);
    });
  });
}

/// Like a real BLE source, a sample can still arrive while [stop] is in flight.
class _SlowStopSource extends StubHeartRateSource {
  bool emittedDuringStop = false;

  @override
  Future<void> stop() async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    emit(_sampleAt(clock.now()));
    emittedDuringStop = true;
    await super.stop();
  }
}
