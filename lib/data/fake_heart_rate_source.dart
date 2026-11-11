import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:pulselink/data/heart_rate_source.dart';
import 'package:pulselink/domain/heart_rate_sample.dart';
import 'package:pulselink/domain/positive_int.dart';

/// Simulated heart rate for demo mode, screenshots and tests.
///
/// Emits one sample per [interval]. The bpm drifts smoothly toward a target
/// that changes every so often, like effort changing during a workout, with a
/// little beat-to-beat noise. Pass a seeded [Random] for repeatable output.
class FakeHeartRateSource implements HeartRateSource {
  new({
    Random? random,
    this.interval = const Duration(seconds: 1),
    PositiveInt? minBpm,
    PositiveInt? maxBpm,
    double initialBpm = 72,
  }) : minBpm = minBpm ?? PositiveInt(55),
       maxBpm = maxBpm ?? PositiveInt(175),
       _random = random ?? Random(),
       _bpm = initialBpm,
       _targetBpm = initialBpm;

  final Duration interval;
  final PositiveInt minBpm;
  final PositiveInt maxBpm;

  final Random _random;
  final _controller = StreamController<HeartRateSample>.broadcast();
  Timer? _timer;
  double _bpm;
  double _targetBpm;
  int _samplesUntilNewTarget = 0;

  @override
  bool get isSimulated => true;

  @override
  Stream<HeartRateSample> get samples => _controller.stream;

  @override
  Future<void> start() async {
    _timer ??= Timer.periodic(interval, (_) => _emitSample());
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  void _emitSample() {
    if (_samplesUntilNewTarget <= 0) {
      _targetBpm =
          minBpm.value + _random.nextDouble() * (maxBpm.value - minBpm.value);
      _samplesUntilNewTarget = 20 + _random.nextInt(40);
    }
    _samplesUntilNewTarget--;

    final noise = (_random.nextDouble() - 0.5) * 3;
    _bpm = (_bpm + (_targetBpm - _bpm) * 0.08 + noise).clamp(
      minBpm.value.toDouble(),
      maxBpm.value.toDouble(),
    );

    // Can't throw: _bpm is clamped to at least minBpm, which is above 0.
    final bpm = PositiveInt(_bpm.round());
    _controller.add(
      HeartRateSample.measured(
        bpm: bpm,
        timestamp: clock.now(),
        contact: MeasuredContact.detected,
        rrIntervals: [Duration(microseconds: (60000000 / bpm.value).round())],
      ),
    );
  }
}
