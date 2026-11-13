import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulselink/data/fake_heart_rate_source.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';

final _start = DateTime(2026, 11, 11, 10);

/// Runs [body] with fake time, and a [clock] that follows it.
void _withFakeTime(void Function(FakeAsync async) body) {
  fakeAsync((async) => withClock(async.getClock(_start), () => body(async)));
}

/// Starts [source], lets [duration] pass, and returns what it emitted. The
/// fake only produces measured samples, so anything else fails the test.
List<MeasuredHeartRateSample> _run(
  FakeAsync async,
  FakeHeartRateSource source,
  Duration duration,
) {
  final samples = <MeasuredHeartRateSample>[];
  source.samples.listen(
    (sample) => samples.add(switch (sample) {
      final MeasuredHeartRateSample measured => measured,
      UnavailableHeartRateSample() => fail('Unexpected: $sample'),
    }),
  );
  unawaited(source.start());
  async.elapse(duration);
  return samples;
}

void main() {
  group('FakeHeartRateSource', () {
    test('is simulated', () {
      expect(FakeHeartRateSource().isSimulated, isTrue);
    });

    test('emits nothing before start', () {
      _withFakeTime((async) {
        final source = FakeHeartRateSource();
        final samples = <HeartRateSample>[];
        source.samples.listen(samples.add);
        async.elapse(const Duration(seconds: 5));
        expect(samples, isEmpty);
      });
    });

    test('emits one sample per interval, stamped with the clock', () {
      _withFakeTime((async) {
        final samples = _run(
          async,
          FakeHeartRateSource(random: Random(1)),
          const Duration(seconds: 3),
        );
        expect(samples.map((s) => s.timestamp), [
          _start.add(const Duration(seconds: 1)),
          _start.add(const Duration(seconds: 2)),
          _start.add(const Duration(seconds: 3)),
        ]);
      });
    });

    test('honors a custom interval', () {
      _withFakeTime((async) {
        final samples = _run(
          async,
          FakeHeartRateSource(interval: const Duration(milliseconds: 250)),
          const Duration(seconds: 1),
        );
        expect(samples, hasLength(4));
      });
    });

    test('produces plausible, moving samples within its range', () {
      _withFakeTime((async) {
        final samples = _run(
          async,
          FakeHeartRateSource(random: Random(7)),
          const Duration(minutes: 5),
        );
        expect(samples, hasLength(300));
        for (final sample in samples) {
          expect(
            sample.bpm.value,
            inInclusiveRange(
              FakeHeartRateSource.minBpm,
              FakeHeartRateSource.maxBpm,
            ),
          );
          expect(sample.contact, MeasuredContact.detected);
          // One RR interval matching the bpm: 60 s / bpm.
          expect(sample.rrIntervals, hasLength(1));
          final impliedBpm =
              60000000 / sample.rrIntervals.single.inMicroseconds;
          expect(impliedBpm, closeTo(sample.bpm.value, 0.01));
        }
        final distinct = samples.map((s) => s.bpm.value).toSet();
        expect(distinct.length, greaterThan(10), reason: 'bpm should move');
      });
    });

    test('changes smoothly, without big jumps between samples', () {
      _withFakeTime((async) {
        final samples = _run(
          async,
          FakeHeartRateSource(random: Random(3)),
          const Duration(minutes: 5),
        );
        for (var i = 1; i < samples.length; i++) {
          expect(
            (samples[i].bpm.value - samples[i - 1].bpm.value).abs(),
            lessThan(15),
          );
        }
      });
    });

    test('is repeatable for the same seed', () {
      List<int> bpms(int seed) {
        late List<int> result;
        _withFakeTime((async) {
          result = _run(
            async,
            FakeHeartRateSource(random: Random(seed)),
            const Duration(seconds: 30),
          ).map((s) => s.bpm.value).toList();
        });
        return result;
      }

      expect(bpms(42), bpms(42));
      expect(bpms(42), isNot(bpms(43)));
    });

    test('stops emitting after stop, and resumes after start', () {
      _withFakeTime((async) {
        final source = FakeHeartRateSource();
        final samples = _run(async, source, const Duration(seconds: 2));
        unawaited(source.stop());
        async.elapse(const Duration(seconds: 5));
        expect(samples, hasLength(2));

        unawaited(source.start());
        async.elapse(const Duration(seconds: 1));
        expect(samples, hasLength(3));
      });
    });

    test('calling start twice does not double the rate', () {
      _withFakeTime((async) {
        final source = FakeHeartRateSource();
        unawaited(source.start());
        final samples = _run(async, source, const Duration(seconds: 3));
        expect(samples, hasLength(3));
      });
    });

    test('start after dispose does nothing', () {
      _withFakeTime((async) {
        final source = FakeHeartRateSource();
        unawaited(source.dispose());
        async.flushMicrotasks();
        unawaited(source.start());
        async.elapse(const Duration(seconds: 5));
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('closes its stream on dispose', () {
      _withFakeTime((async) {
        final source = FakeHeartRateSource();
        var isDone = false;
        source.samples.listen(null, onDone: () => isDone = true);
        unawaited(source.start());
        unawaited(source.dispose());
        async.flushMicrotasks();
        expect(isDone, isTrue);
      });
    });
  });
}
